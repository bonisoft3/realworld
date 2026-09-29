import Testing
import Foundation
@testable import RealWorld
@testable import Omnishell

@Suite("ElectricShapeSync iOS Tests")
struct ElectricShapeSyncTests {
    @Test func testElectricShapeAppliesInsertAndUpdateMessages() throws {
        let app = RealWorldNativeApp(dbPath: ":memory:")
        defer { app.close() }
        app.start()

        guard let jscEngine = app.engine as? JavaScriptCoreOmnishellEngine else {
            Issue.record("Engine must be JavaScriptCoreOmnishellEngine")
            return
        }

        let insertMsg = """
        [
            {
                "key": "art_ios_sync_1",
                "offset": "10_0",
                "headers": { "operation": "insert", "lsn": "200" },
                "value": {
                    "id": "art_ios_sync_1",
                    "slug": "electric-shape-ios-live",
                    "title": "Electric Shape iOS Live",
                    "description": "Real-time CDC synced into iOS SQLite",
                    "body": "This article was materialized directly from an Electric shape stream on iOS.",
                    "author_id": "user_electric",
                    "created_at": "2026-09-14T17:00:00.000Z",
                    "updated_at": "2026-09-14T17:00:00.000Z"
                }
            }
        ]
        """

        _ = jscEngine.evaluateJs("__electricClient.applyBatch('article', ['id'], JSON.parse(`\(insertMsg)`))")

        // Verify offset in KV
        let offset = jscEngine.evaluateJs("__electricClient.getOffset('article')")?.toString()
        #expect(offset == "10_0")

        // Verify row in SQLite
        let rows = try app.db.query("SELECT slug, title FROM article WHERE id = ?;", params: ["art_ios_sync_1"])
        #expect(rows.count == 1)
        #expect(rows[0]["slug"] as? String == "electric-shape-ios-live")
        #expect(rows[0]["title"] as? String == "Electric Shape iOS Live")

        // Apply update
        let updateMsg = """
        {
            "key": "art_ios_sync_1",
            "offset": "10_1",
            "headers": { "operation": "update", "lsn": "201" },
            "value": {
                "id": "art_ios_sync_1",
                "slug": "electric-shape-ios-live",
                "title": "Electric Shape iOS Live (Updated)",
                "description": "Real-time CDC synced into iOS SQLite",
                "body": "Updated content on iOS.",
                "author_id": "user_electric",
                "created_at": "2026-09-14T17:00:00.000Z",
                "updated_at": "2026-09-14T17:05:00.000Z"
            }
        }
        """

        _ = jscEngine.evaluateJs("__electricClient.applyMessage('article', ['id'], JSON.parse(`\(updateMsg)`))")

        let updatedOffset = jscEngine.evaluateJs("__electricClient.getOffset('article')")?.toString()
        #expect(updatedOffset == "10_1")

        let updatedRows = try app.db.query("SELECT title FROM article WHERE id = ?;", params: ["art_ios_sync_1"])
        #expect(updatedRows.count == 1)
        #expect(updatedRows[0]["title"] as? String == "Electric Shape iOS Live (Updated)")
    }

    @Test func testElectricShapeAppliesDeleteMessages() throws {
        let app = RealWorldNativeApp(dbPath: ":memory:")
        defer { app.close() }
        app.start()

        guard let jscEngine = app.engine as? JavaScriptCoreOmnishellEngine else {
            Issue.record("Engine must be JavaScriptCoreOmnishellEngine")
            return
        }

        // art_3 initially exists in seed
        let before = try app.db.query("SELECT id FROM article WHERE id = 'art_3';")
        #expect(!before.isEmpty)

        let deleteMsg = """
        {
            "key": "art_3",
            "offset": "20_0",
            "headers": { "operation": "delete", "lsn": "202" },
            "value": { "id": "art_3" }
        }
        """

        _ = jscEngine.evaluateJs("__electricClient.applyMessage('article', ['id'], JSON.parse(`\(deleteMsg)`))")

        let after = try app.db.query("SELECT id FROM article WHERE id = 'art_3';")
        #expect(after.isEmpty)

        let offset = jscEngine.evaluateJs("__electricClient.getOffset('article')")?.toString()
        #expect(offset == "20_0")
    }
}
