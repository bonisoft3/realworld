package com.pronto.realworld

import com.pronto.omnishell.OmnishellEngine
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import org.junit.jupiter.api.Test
import org.junit.jupiter.api.assertThrows
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class RealWorldDivActionHandlerTest {

    class MockOmnishellEngine : OmnishellEngine {
        val dispatchedActions = mutableListOf<String>()
        override val uiAst: StateFlow<String> = MutableStateFlow("")
        override fun start() {}
        override fun dispatchAction(action: String) {
            dispatchedActions.add(action)
        }
        override fun close() {}
    }

    @Test
    fun testHandleProntoAction() {
        val engine = MockOmnishellEngine()
        val handler = RealWorldDivActionHandler(engine)

        val handled = handler.handleAction("pronto://event/TOGGLE_FAVORITE?slug=how-to-build")
        assertTrue(handled)
        assertEquals(1, engine.dispatchedActions.size)
        assertEquals("pronto://event/TOGGLE_FAVORITE?slug=how-to-build", engine.dispatchedActions[0])
    }

    @Test
    fun testIgnoreNonProntoScheme() {
        val engine = MockOmnishellEngine()
        val handler = RealWorldDivActionHandler(engine)

        val handled = handler.handleAction("https://example.com/article")
        assertFalse(handled)
        assertEquals(0, engine.dispatchedActions.size)
    }

    @Test
    fun testMalformedUriThrows() {
        val engine = MockOmnishellEngine()
        val handler = RealWorldDivActionHandler(engine)

        assertThrows<IllegalArgumentException> {
            handler.handleAction("http://invalid uri with spaces")
        }
    }
}
