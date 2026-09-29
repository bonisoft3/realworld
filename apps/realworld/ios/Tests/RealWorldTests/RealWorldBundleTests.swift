import Testing
import Foundation
@testable import RealWorld
@testable import Omnishell

@Suite("RealWorld iOS Bundle Tests")
struct RealWorldBundleTests {
    @Test func testAllTwelveTablesExistInNormalizedSchema() throws {
        let app = RealWorldNativeApp(dbPath: ":memory:")
        defer { app.close() }
        app.start()

        let tables = [
            "app_user", "me", "article", "article_tag", "comment",
            "favorite", "bookmark", "follow", "article_stats",
            "tag_count", "favorite_index", "favorite_count"
        ]

        for table in tables {
            let rows = try app.db.query("SELECT COUNT(*) as c FROM \(table);")
            #expect(rows.count == 1, "Table \(table) should exist and be queryable")
            #expect(rows[0]["c"] != nil)
        }
    }

    @Test func testInitialDivKitAstEmission() {
        let app = RealWorldNativeApp(dbPath: ":memory:")
        defer { app.close() }
        app.start()

        let ast = app.uiAst
        #expect(ast.contains("\"card\""))
        #expect(ast.contains("conduit_realworld_sdui"))
        #expect(ast.contains("How to Build a Local-First App with Pronto and DivKit"))
        #expect(ast.contains("The Type Duality of Conduit"))
    }

    @Test func testActionDispatchToReadingListTab() async throws {
        let app = RealWorldNativeApp(dbPath: ":memory:")
        defer { app.close() }
        app.start()

        let handled = app.actionHandler.handleAction("pronto://event/SELECT_TAB?tab=bookmarks")
        #expect(handled == true)

        var updated = false
        for _ in 0..<20 {
            if app.uiAst.contains("Reading List") {
                updated = true
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        #expect(updated == true)
    }

    @Test func testToggleBookmarkActionUpdatesDatabaseAndAst() async throws {
        let app = RealWorldNativeApp(dbPath: ":memory:")
        defer { app.close() }
        app.start()

        // art_2 ("the-type-duality-of-conduit") is initially not bookmarked by user_jessie
        let before = try app.db.query("SELECT * FROM bookmark WHERE user_id = 'user_jessie' AND article_id = 'art_2';")
        #expect(before.isEmpty)

        // Toggle bookmark ON
        _ = app.actionHandler.handleAction("pronto://event/TOGGLE_BOOKMARK?slug=the-type-duality-of-conduit")

        var bookmarked = false
        for _ in 0..<20 {
            let after = try app.db.query("SELECT * FROM bookmark WHERE user_id = 'user_jessie' AND article_id = 'art_2';")
            if !after.isEmpty {
                bookmarked = true
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        #expect(bookmarked == true)

        // Toggle bookmark OFF
        _ = app.actionHandler.handleAction("pronto://event/TOGGLE_BOOKMARK?slug=the-type-duality-of-conduit")

        var removed = false
        for _ in 0..<20 {
            let after = try app.db.query("SELECT * FROM bookmark WHERE user_id = 'user_jessie' AND article_id = 'art_2';")
            if after.isEmpty {
                removed = true
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        #expect(removed == true)
    }

    @Test func testSearchQueryFilterAction() async throws {
        let app = RealWorldNativeApp(dbPath: ":memory:")
        defer { app.close() }
        app.start()

        _ = app.actionHandler.handleAction("pronto://event/SEARCH?query=electric")

        var searchApplied = false
        for _ in 0..<20 {
            let ast = app.uiAst
            // Should contain electric article and not other articles
            if ast.contains("ElectricSQL Shapes over SSE") && !ast.contains("The Type Duality of Conduit") {
                searchApplied = true
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        #expect(searchApplied == true)
    }

    @Test func testNavigateArticleDetailAndComments() async throws {
        let app = RealWorldNativeApp(dbPath: ":memory:")
        defer { app.close() }
        app.start()

        _ = app.actionHandler.handleAction("pronto://event/VIEW_ARTICLE?slug=how-to-build-local-first-pronto-divkit")

        var detailViewLoaded = false
        for _ in 0..<20 {
            let ast = app.uiAst
            if ast.contains("Formal verification of the reducer ensures state transitions are always sound.") {
                detailViewLoaded = true
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }

        #expect(detailViewLoaded == true)
    }

    @Test func testNavigateToNewArticleEditorAndPublish() async throws {
        let app = RealWorldNativeApp(dbPath: ":memory:")
        defer { app.close() }
        app.start()

        #expect(app.uiAst.contains("✍ New Article"))

        _ = app.actionHandler.handleAction("pronto://event/NAVIGATE?screen=editor")

        var editorLoaded = false
        for _ in 0..<20 {
            if app.uiAst.contains("Writing as @jessie") {
                editorLoaded = true
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        #expect(editorLoaded == true)

        let publishUrl = "pronto://event/PUBLISH_ARTICLE?title=My+First+SDUI+Article&description=Testing+article+creation&body=This+is+a+new+article+created+natively.&tags=sdui+native"
        _ = app.actionHandler.handleAction(publishUrl)

        var published = false
        for _ in 0..<20 {
            let rows = try app.db.query("SELECT * FROM article WHERE slug = 'my-first-sdui-article';")
            if !rows.isEmpty {
                published = true
                break
            }
            try await Task.sleep(nanoseconds: 50_000_000)
        }
        #expect(published == true)
        #expect(app.uiAst.contains("My First SDUI Article"))
    }
}
