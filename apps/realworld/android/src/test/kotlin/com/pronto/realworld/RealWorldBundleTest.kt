package com.pronto.realworld

import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class RealWorldBundleTest {
    private lateinit var app: RealWorldNativeApp

    @BeforeEach
    fun setUp() {
        app = RealWorldNativeApp(dbPath = "jdbc:sqlite::memory:")
        app.start()
    }

    @AfterEach
    fun tearDown() {
        app.close()
    }

    @Test
    fun testInitialEmissionShowsHomeFeedWithPressIdentity() {
        val ast = app.uiAst.value
        assertTrue(ast.contains("conduit"))
        assertTrue(ast.contains("Global Feed"))
        assertTrue(ast.contains("How to Build a Local-First App"))
        assertTrue(ast.contains("\"font_family\":\"serif\""))
        assertTrue(ast.contains("#1D6A4F"))
        assertTrue(ast.contains("#FBFAF7"))
        assertTrue(ast.contains("@jessie"))
    }

    @Test
    fun testSelectTabSwitchesToYourFeed() = runBlocking {
        app.dispatchAction("pronto://event/SELECT_TAB?tab=feed")

        var retries = 0
        while (app.uiAst.value.contains("The Type Duality of Conduit") && retries < 25) {
            delay(50)
            retries++
        }

        val ast = app.uiAst.value
        assertTrue(ast.contains("How to Build a Local-First App"))
        assertFalse(ast.contains("The Type Duality of Conduit"))
    }

    @Test
    fun testSelectTagFiltersFeed() = runBlocking {
        app.dispatchAction("pronto://event/SELECT_TAG?tag=editorial")

        var retries = 0
        while (app.uiAst.value.contains("ElectricSQL Shapes over SSE") && retries < 25) {
            delay(50)
            retries++
        }

        val ast = app.uiAst.value
        assertTrue(ast.contains("The Type Duality of Conduit"))
        assertFalse(ast.contains("ElectricSQL Shapes over SSE"))
    }

    @Test
    fun testReadingListBookmarksFlow() = runBlocking {
        val initialAst = app.uiAst.value
        assertTrue(initialAst.contains("Reading List (1)"))

        // Bookmark art_2
        app.dispatchAction("pronto://event/TOGGLE_BOOKMARK?slug=the-type-duality-of-conduit")

        var retries = 0
        while (!app.uiAst.value.contains("Reading List (2)") && retries < 25) {
            delay(50)
            retries++
        }
        assertTrue(app.uiAst.value.contains("Reading List (2)"))

        // Switch to bookmarks tab
        app.dispatchAction("pronto://event/SELECT_TAB?tab=bookmarks")
        retries = 0
        while (!app.uiAst.value.contains("The Type Duality of Conduit") && retries < 25) {
            delay(50)
            retries++
        }
        val bookmarkAst = app.uiAst.value
        assertTrue(bookmarkAst.contains("The Type Duality of Conduit"))
        assertTrue(bookmarkAst.contains("How to Build a Local-First App"))

        // Unbookmark art_2
        app.dispatchAction("pronto://event/TOGGLE_BOOKMARK?slug=the-type-duality-of-conduit")
        retries = 0
        while (!app.uiAst.value.contains("Reading List (1)") && retries < 25) {
            delay(50)
            retries++
        }
        assertTrue(app.uiAst.value.contains("Reading List (1)"))
    }

    @Test
    fun testSearchFilterArticles() = runBlocking {
        app.dispatchAction("pronto://event/SEARCH?query=isomorphic")

        var retries = 0
        while (app.uiAst.value.contains("The Type Duality of Conduit") && retries < 25) {
            delay(50)
            retries++
        }

        val ast = app.uiAst.value
        assertTrue(ast.contains("How to Build a Local-First App"))
        assertFalse(ast.contains("The Type Duality of Conduit"))
    }

    @Test
    fun testToggleFavoriteMovesCountOnTheSpot() = runBlocking {
        val initialAst = app.uiAst.value
        assertTrue(initialAst.contains("♡ 42"))

        app.dispatchAction("pronto://event/TOGGLE_FAVORITE?slug=how-to-build-local-first-pronto-divkit")

        var retries = 0
        while (!app.uiAst.value.contains("♥ 43") && retries < 25) {
            delay(50)
            retries++
        }

        val favoritedAst = app.uiAst.value
        assertTrue(favoritedAst.contains("♥ 43"))

        app.dispatchAction("pronto://event/TOGGLE_FAVORITE?slug=how-to-build-local-first-pronto-divkit")
        retries = 0
        while (!app.uiAst.value.contains("♡ 42") && retries < 25) {
            delay(50)
            retries++
        }
        assertTrue(app.uiAst.value.contains("♡ 42"))
    }

    @Test
    fun testNavigateToArticleDetailAndBack() = runBlocking {
        app.dispatchAction("pronto://event/VIEW_ARTICLE?slug=the-type-duality-of-conduit")

        var retries = 0
        while (!app.uiAst.value.contains("← Back to feed") && retries < 25) {
            delay(50)
            retries++
        }

        val detailAst = app.uiAst.value
        assertTrue(detailAst.contains("← Back to feed"))
        assertTrue(detailAst.contains("Conduit is an editorial ground"))
        assertTrue(detailAst.contains("+ Follow"))

        app.dispatchAction("pronto://event/NAVIGATE?screen=home")
        retries = 0
        while (!app.uiAst.value.contains("Popular Tags") && retries < 25) {
            delay(50)
            retries++
        }

        assertTrue(app.uiAst.value.contains("Popular Tags"))
    }

    @Test
    fun testAddCommentAndPersist() = runBlocking {
        app.dispatchAction("pronto://event/VIEW_ARTICLE?slug=how-to-build-local-first-pronto-divkit")
        app.dispatchAction("pronto://event/ADD_COMMENT?slug=how-to-build-local-first-pronto-divkit&body=Great+read")

        var retries = 0
        while (!app.uiAst.value.contains("Great read") && retries < 25) {
            delay(50)
            retries++
        }

        val ast = app.uiAst.value
        assertTrue(ast.contains("Great read"))
        assertTrue(ast.contains("Comments (2)"))
    }

    @Test
    fun testErrorBoundaryOnMalformedAst() {
        val fallback = app.divKitHost.parseAstOrFallback("{ invalid json")
        assertTrue(fallback.contains("error_boundary_fallback"))
        assertTrue(fallback.contains("Native Render Error"))

        val valid = app.divKitHost.parseAstOrFallback(app.uiAst.value)
        assertEquals(app.uiAst.value, valid)
    }

    @Test
    fun testComposeAppActionAndRender() {
        val composeApp = RealWorldComposeApp(app)
        val rendered = composeApp.renderCurrentAst()
        assertTrue(rendered.contains("conduit"))
        assertTrue(rendered.contains("Global Feed"))

        composeApp.onActionTriggered("pronto://event/TOGGLE_FAVORITE?slug=how-to-build-local-first-pronto-divkit")
    }
}
