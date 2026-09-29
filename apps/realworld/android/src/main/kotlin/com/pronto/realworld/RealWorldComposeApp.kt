package com.pronto.realworld

import com.pronto.omnishell.OmnishellEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class RealWorldComposeApp(
    private val app: RealWorldNativeApp,
    private val uiScope: CoroutineScope = CoroutineScope(Dispatchers.Default)
) {
    val uiAst: StateFlow<String> = app.uiAst

    fun onActionTriggered(actionUri: String) {
        uiScope.launch {
            app.dispatchAction(actionUri)
        }
    }

    fun renderCurrentAst(): String {
        val rawAst = uiAst.value
        return app.divKitHost.parseAstOrFallback(rawAst)
    }
}
