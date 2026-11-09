package com.pronto.realworld

import com.pronto.omnishell.divkit.OmnishellDivKitHost

/**
 * RealWorld DivKit Host delegating to the shared [OmnishellDivKitHost].
 */
class RealWorldDivKitHost {
    val delegate = OmnishellDivKitHost()

    val currentCardId: String
        get() = delegate.currentCardId

    val lastRenderedAst: String
        get() = delegate.lastRenderedAst

    val hasError: Boolean
        get() = delegate.hasError

    fun render(astJson: String, onAction: (String) -> Unit): Boolean =
        delegate.render(astJson, onAction)

    fun parseAstOrFallback(astJson: String): String =
        delegate.parseAstOrFallback(astJson)
}
