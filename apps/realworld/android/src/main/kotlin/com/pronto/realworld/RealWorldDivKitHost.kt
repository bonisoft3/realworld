package com.pronto.realworld

import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject

class RealWorldDivKitHost(
    private val json: Json = Json { ignoreUnknownKeys = true }
) {
    fun parseAstOrFallback(astJson: String): String {
        return try {
            val element = json.parseToJsonElement(astJson).jsonObject
            if (!element.containsKey("card")) {
                renderFallbackErrorScreen("DivKit AST missing 'card' root element", astJson)
            } else {
                astJson
            }
        } catch (e: Exception) {
            renderFallbackErrorScreen("Invalid DivKit JSON AST: ${e.message}", astJson)
        }
    }

    private fun renderFallbackErrorScreen(errorMessage: String, rawAst: String): String {
        val escapedMessage = json.encodeToString(errorMessage)
        return """
            {
              "card": {
                "log_id": "error_boundary_fallback",
                "states": [
                  {
                    "state_id": 0,
                    "div": {
                      "type": "container",
                      "orientation": "vertical",
                      "paddings": { "top": 32, "bottom": 32, "left": 16, "right": 16 },
                      "items": [
                        {
                          "type": "text",
                          "text": "Native Render Error",
                          "font_size": 20,
                          "font_weight": "bold",
                          "text_color": "#A93226"
                        },
                        {
                          "type": "text",
                          "text": $escapedMessage,
                          "font_size": 14,
                          "text_color": "#16181A",
                          "margins": { "top": 8 }
                        }
                      ]
                    }
                  }
                ]
              }
            }
        """.trimIndent()
    }
}
