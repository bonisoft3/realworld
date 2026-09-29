package com.pronto.realworld

import com.pronto.omnishell.OmnishellEngine
import java.net.URI

class RealWorldDivActionHandler(
    private val engine: OmnishellEngine
) {
    fun handleAction(actionUri: String): Boolean {
        val uri = try {
            URI.create(actionUri)
        } catch (e: IllegalArgumentException) {
            throw IllegalArgumentException("Malformed action URI: $actionUri", e)
        }

        if (uri.scheme != "pronto" || uri.host != "event") {
            return false
        }

        engine.dispatchAction(actionUri)
        return true
    }
}
