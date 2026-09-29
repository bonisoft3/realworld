package com.pronto.realworld

import android.app.Activity
import android.content.Context
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.graphics.Color
import android.os.Bundle
import android.util.Log
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.webkit.ConsoleMessage
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.WebView
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : Activity() {
    private lateinit var headlessWebView: WebView
    lateinit var renderer: DivKitAndroidViewRenderer
    lateinit var rootContainer: LinearLayout
    val kvStorage = mutableMapOf<String, String>()
    private lateinit var sqliteDb: SQLiteDatabase

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        sqliteDb = openOrCreateDatabase("realworld.db", Context.MODE_PRIVATE, null)

        val frameLayout = FrameLayout(this).apply {
            fitsSystemWindows = true
            setBackgroundColor(Color.parseColor("#FBFAF7"))
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        val scrollView = ScrollView(this).apply {
            isFillViewport = false
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }

        rootContainer = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = Gravity.CENTER_HORIZONTAL
            }
        }

        scrollView.addView(rootContainer)
        frameLayout.addView(scrollView)
        setContentView(frameLayout)

        renderer = DivKitAndroidViewRenderer(this) { actionUri ->
            dispatchNativeAction(actionUri)
        }

        setupHeadlessEngine(frameLayout)
    }

    private fun setupHeadlessEngine(frameLayout: FrameLayout) {
        headlessWebView = WebView(this).apply {
            visibility = View.GONE
            layoutParams = ViewGroup.LayoutParams(0, 0)
            settings.javaScriptEnabled = true
            webChromeClient = object : WebChromeClient() {
                override fun onConsoleMessage(consoleMessage: ConsoleMessage?): Boolean {
                    Log.d("ProntoRealWorldJS", "${consoleMessage?.message()} [${consoleMessage?.sourceId()}:${consoleMessage?.lineNumber()}]")
                    return true
                }
            }
            addJavascriptInterface(NativeHost(this@MainActivity, sqliteDb), "NativeHost")
        }
        frameLayout.addView(headlessWebView)

        val bundleCode = loadBundleScript()
        val engineBootstrap = """
            (function() {
                globalThis.__omnishellStorage = {
                    kv: {
                        get: function(k) { return NativeHost.kvGet(k); },
                        set: function(k, v) { NativeHost.kvSet(k, String(v)); },
                        delete: function(k) { return Boolean(NativeHost.kvDelete(k)); },
                        clear: function() { NativeHost.kvClear(); },
                        keys: function() { return JSON.parse(NativeHost.kvKeys()); }
                    },
                    sql: {
                        exec: function(q, p) {
                            var res = NativeHost.sqlExec(q, p ? JSON.stringify(p) : "[]");
                            return JSON.parse(res);
                        },
                        query: function(q, p) {
                            var res = NativeHost.sqlQuery(q, p ? JSON.stringify(p) : "[]");
                            return JSON.parse(res);
                        }
                    }
                };
                window.storage = globalThis.__omnishellStorage;

                window.emitUiAst = function(ast) {
                    NativeHost.onUiAstEmitted(typeof ast === 'string' ? ast : JSON.stringify(ast));
                };
                globalThis.emitUiAst = window.emitUiAst;

                window.onAction = function(cb) {
                    window.__actionHandler = cb;
                };
                globalThis.onAction = window.onAction;

                window.__dispatchNativeAction = function(uri) {
                    if (window.__actionHandler) {
                        window.__actionHandler(uri);
                        return "dispatched: " + uri;
                    }
                    return "no_handler";
                };
            })();
        """.trimIndent()

        val fullHtml = """
            <!DOCTYPE html>
            <html>
            <head><meta charset="utf-8"></head>
            <body>
            <script>
            $engineBootstrap
            $bundleCode
            </script>
            </body>
            </html>
        """.trimIndent()

        headlessWebView.loadDataWithBaseURL(null, fullHtml, "text/html", "UTF-8", null)
    }

    private fun dispatchNativeAction(actionUri: String) {
        Log.d("ProntoAction", "dispatchNativeAction: $actionUri")
        val escaped = actionUri.replace("\\", "\\\\").replace("'", "\\'")
        runOnUiThread {
            headlessWebView.evaluateJavascript("__dispatchNativeAction('$escaped')") { result ->
                Log.d("ProntoAction", "evaluateJavascript result: $result")
            }
        }
    }

    @Deprecated("Deprecated in Java")
    override fun onBackPressed() {
        dispatchNativeAction("pronto://event/NAVIGATE?screen=home")
    }

    private fun loadBundleScript(): String {
        return assets.open("realworld_bundle.js").bufferedReader().use { it.readText() }
    }

    override fun onDestroy() {
        super.onDestroy()
        headlessWebView.destroy()
        sqliteDb.close()
    }

    class NativeHost(private val activity: MainActivity, private val db: SQLiteDatabase) {
        @JavascriptInterface
        fun onUiAstEmitted(json: String) {
            Log.d("ProntoAST", "AST received, length=${json.length}: $json")
            activity.runOnUiThread {
                activity.renderer.renderAst(json, activity.rootContainer)
            }
        }

        @JavascriptInterface
        fun kvGet(key: String): String? {
            return activity.kvStorage[key]
        }

        @JavascriptInterface
        fun kvSet(key: String, value: String) {
            activity.kvStorage[key] = value
        }

        @JavascriptInterface
        fun kvDelete(key: String): Boolean {
            return activity.kvStorage.remove(key) != null
        }

        @JavascriptInterface
        fun kvClear() {
            activity.kvStorage.clear()
        }

        @JavascriptInterface
        fun kvKeys(): String {
            return JSONArray(activity.kvStorage.keys).toString()
        }

        @JavascriptInterface
        fun sqlExec(sql: String, paramsJson: String?): String {
            Log.d("ProntoSQL", "sqlExec: $sql | params: $paramsJson")
            val bindArgs = parseParams(paramsJson)
            if (bindArgs.isEmpty()) {
                db.execSQL(sql)
            } else {
                db.execSQL(sql, bindArgs.toTypedArray())
            }
            return JSONObject().put("rowsAffected", 1).put("lastInsertRowId", 0).toString()
        }

        @JavascriptInterface
        fun sqlQuery(sql: String, paramsJson: String?): String {
            Log.d("ProntoSQL", "sqlQuery: $sql | params: $paramsJson")
            val stringArgs = parseStringParams(paramsJson)
            val cursor = db.rawQuery(sql, stringArgs)
            val jsonArray = JSONArray()
            cursor.use { c ->
                val colNames = c.columnNames
                while (c.moveToNext()) {
                    val row = JSONObject()
                    for (i in 0 until c.columnCount) {
                        val name = colNames[i]
                        when (c.getType(i)) {
                            Cursor.FIELD_TYPE_NULL -> row.put(name, JSONObject.NULL)
                            Cursor.FIELD_TYPE_INTEGER -> row.put(name, c.getLong(i))
                            Cursor.FIELD_TYPE_FLOAT -> row.put(name, c.getDouble(i))
                            Cursor.FIELD_TYPE_STRING -> row.put(name, c.getString(i))
                            Cursor.FIELD_TYPE_BLOB -> row.put(name, String(c.getBlob(i)))
                        }
                    }
                    jsonArray.put(row)
                }
            }
            val result = jsonArray.toString()
            Log.d("ProntoSQL", "sqlQuery result count=${jsonArray.length()}")
            return result
        }

        private fun parseParams(paramsJson: String?): List<Any?> {
            if (paramsJson.isNullOrBlank() || paramsJson == "[]") return emptyList()
            val arr = JSONArray(paramsJson)
            val list = mutableListOf<Any?>()
            for (i in 0 until arr.length()) {
                val item = arr.get(i)
                when (item) {
                    JSONObject.NULL -> list.add(null)
                    is Boolean -> list.add(if (item) 1 else 0)
                    else -> list.add(item)
                }
            }
            return list
        }

        private fun parseStringParams(paramsJson: String?): Array<String>? {
            if (paramsJson.isNullOrBlank() || paramsJson == "[]") return null
            val arr = JSONArray(paramsJson)
            val list = mutableListOf<String>()
            for (i in 0 until arr.length()) {
                val item = arr.get(i)
                if (item == JSONObject.NULL) {
                    list.add("")
                } else if (item is Boolean) {
                    list.add(if (item) "1" else "0")
                } else {
                    list.add(item.toString())
                }
            }
            return list.toTypedArray()
        }
    }
}
