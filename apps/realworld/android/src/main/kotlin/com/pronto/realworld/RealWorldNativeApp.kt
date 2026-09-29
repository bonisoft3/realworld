package com.pronto.realworld

import com.pronto.omnishell.OmnishellEngine
import com.pronto.omnishell.QuickJsOmnishellEngine
import com.pronto.omnishell.bridge.NetworkBridge
import com.pronto.omnishell.bridge.StorageBridge
import com.pronto.omnishell.network.OkHttpFetchClient
import com.pronto.omnishell.storage.JdbcSqliteDatabase
import com.pronto.omnishell.storage.SqlDatabase
import com.pronto.omnishell.storage.SqliteKeyValueStore
import kotlinx.coroutines.flow.StateFlow
import java.io.File

class RealWorldNativeApp(
    dbPath: String = "jdbc:sqlite::memory:",
    bundleScript: String? = null
) : AutoCloseable {
    private val db: SqlDatabase = JdbcSqliteDatabase(dbPath)
    private val kvStore = SqliteKeyValueStore(db)
    private val storageBridge = StorageBridge(kvStore, db)
    private val networkBridge = NetworkBridge(OkHttpFetchClient())

    private val script: String = bundleScript ?: loadBundleScript()

    val engine: OmnishellEngine = QuickJsOmnishellEngine(
        networkBridge = networkBridge,
        storageBridge = storageBridge,
        initialScript = script
    )

    val actionHandler = RealWorldDivActionHandler(engine)
    val divKitHost = RealWorldDivKitHost()

    val uiAst: StateFlow<String>
        get() = engine.uiAst

    fun start() {
        engine.start()
    }

    fun dispatchAction(actionUri: String): Boolean {
        return actionHandler.handleAction(actionUri)
    }

    override fun close() {
        engine.close()
    }

    companion object {
        fun loadBundleScript(): String {
            val potentialPaths = listOf(
                "bundle/realworld_bundle.js",
                "apps/realworld/android/bundle/realworld_bundle.js"
            )
            for (p in potentialPaths) {
                val f = File(p)
                if (f.exists()) {
                    return f.readText()
                }
            }
            // Fallback resource loading
            val stream = RealWorldNativeApp::class.java.classLoader?.getResourceAsStream("bundle/realworld_bundle.js")
            if (stream != null) {
                return stream.bufferedReader().use { it.readText() }
            }
            throw IllegalStateException("RealWorld bundle script not found")
        }
    }
}
