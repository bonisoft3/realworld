package com.pronto.realworld

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.text.Editable
import android.text.TextWatcher
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.*
import org.json.JSONArray
import org.json.JSONObject
import java.net.URLEncoder

/**
 * Pure native Android View renderer for DivKit SDUI AST.
 * Inflates real Android View widgets (LinearLayout, TextView, EditText, Button, ScrollView)
 * directly from the DivKit JSON AST without web views or external dependencies.
 */
class DivKitAndroidViewRenderer(
    private val context: Context,
    private val onAction: (String) -> Unit
) {
    // Retains form input values across AST re-renders for interactive input fields
    val formValues = mutableMapOf<String, String>()

    fun renderAst(astJson: String, container: ViewGroup) {
        container.removeAllViews()
        if (astJson.isBlank()) return

        val rootObj = try {
            JSONObject(astJson)
        } catch (e: Exception) {
            val errText = TextView(context).apply {
                text = "Error parsing DivKit AST: ${e.message}"
                setTextColor(Color.RED)
                setPadding(dp(16), dp(16), dp(16), dp(16))
            }
            container.addView(errText)
            return
        }

        val card = rootObj.optJSONObject("card") ?: return
        val states = card.optJSONArray("states") ?: return
        val firstState = states.optJSONObject(0) ?: return
        val rootDiv = firstState.optJSONObject("div") ?: return

        val renderedView = renderNode(rootDiv) ?: return
        container.addView(renderedView)
    }

    fun renderNode(node: JSONObject): View? {
        val type = node.optString("type")
        return when (type) {
            "container" -> renderContainer(node)
            "text" -> renderText(node)
            "input" -> renderInput(node)
            "gallery" -> renderGallery(node)
            "separator" -> renderSeparator(node)
            else -> null
        }
    }

    private fun renderContainer(node: JSONObject): View {
        val isHorizontal = node.optString("orientation") == "horizontal"
        val layout = LinearLayout(context).apply {
            orientation = if (isHorizontal) LinearLayout.HORIZONTAL else LinearLayout.VERTICAL
            layoutParams = ViewGroup.MarginLayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        applyBackgroundAndBorder(node, layout)
        applyPaddings(node, layout)
        applyMargins(node, layout)

        val items = node.optJSONArray("items")
        if (items != null) {
            for (i in 0 until items.length()) {
                val itemObj = items.optJSONObject(i) ?: continue
                val childView = renderNode(itemObj) ?: continue
                
                val itemType = itemObj.optString("type")
                val widthObj = itemObj.optJSONObject("width")
                val heightObj = itemObj.optJSONObject("height")

                var layoutWidth = if (isHorizontal) ViewGroup.LayoutParams.WRAP_CONTENT else ViewGroup.LayoutParams.MATCH_PARENT
                var layoutHeight = ViewGroup.LayoutParams.WRAP_CONTENT
                var weight = 0f

                if (itemType == "separator") {
                    if (heightObj != null) {
                        layoutWidth = ViewGroup.LayoutParams.MATCH_PARENT
                        layoutHeight = dp(heightObj.optInt("value", 1))
                        weight = 0f
                    } else if (widthObj != null && widthObj.optString("type") == "flex") {
                        layoutWidth = 0
                        layoutHeight = dp(1)
                        weight = widthObj.optDouble("value", 1.0).toFloat()
                    } else if (isHorizontal) {
                        layoutWidth = 0
                        layoutHeight = dp(1)
                        weight = 1f
                    } else {
                        layoutWidth = ViewGroup.LayoutParams.MATCH_PARENT
                        layoutHeight = dp(1)
                    }
                } else {
                    if (widthObj != null) {
                        when (widthObj.optString("type")) {
                            "flex" -> {
                                if (isHorizontal) {
                                    layoutWidth = 0
                                    weight = widthObj.optDouble("value", 1.0).toFloat()
                                } else {
                                    layoutWidth = ViewGroup.LayoutParams.MATCH_PARENT
                                }
                            }
                            "fixed", "exact" -> {
                                layoutWidth = dp(widthObj.optInt("value", 0))
                            }
                            "match_parent" -> layoutWidth = ViewGroup.LayoutParams.MATCH_PARENT
                            "wrap_content" -> layoutWidth = ViewGroup.LayoutParams.WRAP_CONTENT
                        }
                    }

                    if (heightObj != null) {
                        when (heightObj.optString("type")) {
                            "flex" -> {
                                if (!isHorizontal) {
                                    layoutHeight = 0
                                    weight = heightObj.optDouble("value", 1.0).toFloat()
                                } else {
                                    layoutHeight = ViewGroup.LayoutParams.WRAP_CONTENT
                                }
                            }
                            "fixed", "exact" -> {
                                layoutHeight = dp(heightObj.optInt("value", 1))
                            }
                            "match_parent" -> layoutHeight = ViewGroup.LayoutParams.MATCH_PARENT
                            "wrap_content" -> layoutHeight = ViewGroup.LayoutParams.WRAP_CONTENT
                        }
                    }
                }

                val lp = LinearLayout.LayoutParams(layoutWidth, layoutHeight, weight)

                var childGravity = 0
                when (itemObj.optString("alignment_vertical")) {
                    "center" -> childGravity = childGravity or Gravity.CENTER_VERTICAL
                    "bottom" -> childGravity = childGravity or Gravity.BOTTOM
                    "top" -> childGravity = childGravity or Gravity.TOP
                }
                when (itemObj.optString("alignment_horizontal")) {
                    "center" -> childGravity = childGravity or Gravity.CENTER_HORIZONTAL
                    "right", "end" -> childGravity = childGravity or Gravity.END
                    "left", "start" -> childGravity = childGravity or Gravity.START
                }
                if (childGravity != 0) {
                    lp.gravity = childGravity
                }

                val margins = itemObj.optJSONObject("margins")
                if (margins != null) {
                    lp.setMargins(
                        dp(margins.optInt("left", 0)),
                        dp(margins.optInt("top", 0)),
                        dp(margins.optInt("right", 0)),
                        dp(margins.optInt("bottom", 0))
                    )
                }

                childView.layoutParams = lp
                layout.addView(childView)
            }
        }

        val actions = node.optJSONArray("actions")
        if (actions != null && actions.length() > 0) {
            val firstAction = actions.optJSONObject(0)
            val url = firstAction?.optString("url")
            if (!url.isNullOrBlank()) {
                layout.isClickable = true
                layout.setOnClickListener {
                    dispatchActionWithFormState(url)
                }
            }
        }

        return layout
    }

    private fun renderText(node: JSONObject): View {
        val textView = TextView(context).apply {
            text = node.optString("text")
            setTextSize(TypedValue.COMPLEX_UNIT_SP, node.optDouble("font_size", 14.0).toFloat())

            val colorStr = node.optString("text_color")
            if (colorStr.isNotBlank()) {
                setTextColor(parseColor(colorStr, Color.BLACK))
            }

            val fontWeight = node.optString("font_weight")
            val isBold = fontWeight == "bold" || fontWeight == "medium"
            val fontFamily = node.optString("font_family")
            typeface = if (fontFamily == "serif") {
                if (isBold) Typeface.create(Typeface.SERIF, Typeface.BOLD) else Typeface.SERIF
            } else {
                if (isBold) Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD) else Typeface.SANS_SERIF
            }

            layoutParams = ViewGroup.MarginLayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        applyBackgroundAndBorder(node, textView)
        applyPaddings(node, textView)
        applyMargins(node, textView)

        val actions = node.optJSONArray("actions")
        if (actions != null && actions.length() > 0) {
            val firstAction = actions.optJSONObject(0)
            val url = firstAction?.optString("url")
            if (!url.isNullOrBlank()) {
                textView.isClickable = true
                textView.setOnClickListener {
                    dispatchActionWithFormState(url)
                }
            }
        }

        return textView
    }

    private fun renderInput(node: JSONObject): View {
        val fieldId = node.optString("id")
        val isMultiline = node.optString("keyboard_type") == "multi_line_text"
        val lineCount = node.optInt("line_count", if (isMultiline) 6 else 1)

        val editText = EditText(context).apply {
            hint = node.optString("hint_text")
            setText(formValues[fieldId] ?: "")
            setTextSize(TypedValue.COMPLEX_UNIT_SP, node.optDouble("font_size", 15.0).toFloat())

            val colorStr = node.optString("text_color")
            if (colorStr.isNotBlank()) {
                setTextColor(parseColor(colorStr, Color.BLACK))
            }

            if (isMultiline) {
                isSingleLine = false
                minLines = lineCount
                gravity = Gravity.TOP or Gravity.START
            } else {
                isSingleLine = true
            }

            val fontWeight = node.optString("font_weight")
            val isBold = fontWeight == "bold"
            val fontFamily = node.optString("font_family")
            typeface = if (fontFamily == "serif") {
                if (isBold) Typeface.create(Typeface.SERIF, Typeface.BOLD) else Typeface.SERIF
            } else {
                if (isBold) Typeface.create(Typeface.SANS_SERIF, Typeface.BOLD) else Typeface.SANS_SERIF
            }

            layoutParams = ViewGroup.MarginLayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )

            addTextChangedListener(object : TextWatcher {
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
                override fun afterTextChanged(s: Editable?) {
                    formValues[fieldId] = s?.toString() ?: ""
                }
            })
        }

        applyBackgroundAndBorder(node, editText)
        applyPaddings(node, editText)
        applyMargins(node, editText)

        return editText
    }

    private fun renderGallery(node: JSONObject): View {
        val scroll = HorizontalScrollView(context).apply {
            isHorizontalScrollBarEnabled = false
            layoutParams = ViewGroup.MarginLayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }
        val innerLayout = LinearLayout(context).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
        }

        val items = node.optJSONArray("items")
        if (items != null) {
            for (i in 0 until items.length()) {
                val itemObj = items.optJSONObject(i) ?: continue
                val childView = renderNode(itemObj) ?: continue
                innerLayout.addView(childView)
            }
        }
        scroll.addView(innerLayout)
        return scroll
    }

    private fun renderSeparator(node: JSONObject): View {
        val heightObj = node.optJSONObject("height")
        val delimiter = node.optJSONObject("delimiter_style")
        val view = View(context)
        if (heightObj != null || delimiter != null) {
            val h = heightObj?.optInt("value", 1) ?: 1
            val colorHex = delimiter?.optString("color") ?: "#E4E1D9"
            view.setBackgroundColor(parseColor(colorHex, Color.LTGRAY))
        }
        return view
    }

    private fun dispatchActionWithFormState(url: String) {
        if (url == "pronto://event/PUBLISH_ARTICLE") {
            val title = formValues["title"] ?: ""
            val desc = formValues["description"] ?: ""
            val body = formValues["body"] ?: ""
            val tags = formValues["tags"] ?: ""
            val coverUrl = formValues["cover_url"] ?: ""

            val params = listOf(
                "title" to title,
                "description" to desc,
                "body" to body,
                "tags" to tags,
                "cover_url" to coverUrl
            ).joinToString("&") { (k, v) -> "$k=${URLEncoder.encode(v, "UTF-8")}" }

            formValues.clear()
            onAction("$url?$params")
        } else {
            onAction(url)
        }
    }

    private fun applyBackgroundAndBorder(node: JSONObject, view: View) {
        val bgArray = node.optJSONArray("background")
        val borderObj = node.optJSONObject("border")

        var solidColor: Int? = null
        if (bgArray != null && bgArray.length() > 0) {
            val firstBg = bgArray.optJSONObject(0)
            if (firstBg?.optString("type") == "solid") {
                val colorHex = firstBg.optString("color")
                if (colorHex.isNotBlank()) {
                    solidColor = parseColor(colorHex, Color.TRANSPARENT)
                }
            }
        }

        var cornerRadius = 0f
        var strokeWidth = 0
        var strokeColor = Color.TRANSPARENT

        if (borderObj != null) {
            cornerRadius = dp(borderObj.optInt("corner_radius", 0)).toFloat()
            val strokeObj = borderObj.optJSONObject("stroke")
            if (strokeObj != null) {
                strokeWidth = dp(strokeObj.optInt("width", 1))
                val strokeColorHex = strokeObj.optString("color")
                if (strokeColorHex.isNotBlank()) {
                    strokeColor = parseColor(strokeColorHex, Color.LTGRAY)
                }
            }
        }

        if (solidColor != null || cornerRadius > 0 || strokeWidth > 0) {
            val drawable = GradientDrawable().apply {
                if (solidColor != null) setColor(solidColor) else setColor(Color.TRANSPARENT)
                if (cornerRadius > 0) setCornerRadius(cornerRadius)
                if (strokeWidth > 0) setStroke(strokeWidth, strokeColor)
            }
            view.background = drawable
        }
    }

    private fun applyPaddings(node: JSONObject, view: View) {
        val paddings = node.optJSONObject("paddings") ?: return
        val l = dp(paddings.optInt("left", 0))
        val t = dp(paddings.optInt("top", 0))
        val r = dp(paddings.optInt("right", 0))
        val b = dp(paddings.optInt("bottom", 0))
        view.setPadding(l, t, r, b)
    }

    private fun applyMargins(node: JSONObject, view: View) {
        val margins = node.optJSONObject("margins") ?: return
        val l = dp(margins.optInt("left", 0))
        val t = dp(margins.optInt("top", 0))
        val r = dp(margins.optInt("right", 0))
        val b = dp(margins.optInt("bottom", 0))
        val lp = view.layoutParams
        if (lp is ViewGroup.MarginLayoutParams) {
            lp.setMargins(l, t, r, b)
            view.layoutParams = lp
        }
    }

    private fun dp(value: Int): Int {
        return TypedValue.applyDimension(
            TypedValue.COMPLEX_UNIT_DIP,
            value.toFloat(),
            context.resources.displayMetrics
        ).toInt()
    }

    private fun parseColor(hex: String, fallback: Int): Int {
        return try {
            Color.parseColor(hex)
        } catch (e: Exception) {
            fallback
        }
    }
}
