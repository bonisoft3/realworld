package com.pronto.realworld

import kotlinx.coroutines.delay
import kotlinx.coroutines.runBlocking
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

class ElectricShapeSyncTest {
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
    fun testAllTwelveTablesExistInNormalizedSchema() {
        val qjsEngine = app.engine as com.pronto.omnishell.QuickJsOmnishellEngine

        val tables = listOf(
            "app_user", "me", "article", "article_tag", "comment",
            "favorite", "bookmark", "follow", "article_stats",
            "tag_count", "favorite_index", "favorite_count"
        )

        for (table in tables) {
            val countResult = qjsEngine.evaluateJs<String>("JSON.stringify(__omnishellStorage.sql.query('SELECT COUNT(*) as c FROM $table;'))")
            assertTrue(countResult.contains("\"c\":"), "Table $table should exist and be queryable")
        }
    }

    @Test
    fun testElectricShapeClientAppliesInsertAndUpdateMessages() = runBlocking {
        val qjsEngine = app.engine as com.pronto.omnishell.QuickJsOmnishellEngine

        // Ingest Electric shape insert message for a new article
        val insertMsg = """
            [
                {
                    "key": "art_sync_1",
                    "offset": "1_0",
                    "headers": { "operation": "insert", "lsn": "100" },
                    "value": {
                        "id": "art_sync_1",
                        "slug": "electric-shape-streaming-live",
                        "title": "Electric Shape Streaming Live",
                        "description": "Real-time CDC synced into local SQLite",
                        "body": "This article was materialized directly from an Electric shape stream.",
                        "author_id": "user_electric",
                        "created_at": "2026-09-14T17:00:00.000Z",
                        "updated_at": "2026-09-14T17:00:00.000Z"
                    }
                }
            ]
        """.trimIndent().replace("\n", "")

        qjsEngine.evaluateJs<Any?>("__electricClient.applyBatch('article', ['id'], JSON.parse('$insertMsg'))")

        // Verify offset is updated in KV store
        val offset = qjsEngine.evaluateJs<String>("__electricClient.getOffset('article')")
        assertEquals("1_0", offset)

        // Verify row is in SQLite
        val queryResult = qjsEngine.evaluateJs<String>("JSON.stringify(__omnishellStorage.sql.query('SELECT slug, title FROM article WHERE id = ?;', ['art_sync_1']))")
        assertTrue(queryResult.contains("electric-shape-streaming-live"))

        // Ingest an Electric update message modifying the title
        val updateMsg = """
            {
                "key": "art_sync_1",
                "offset": "1_1",
                "headers": { "operation": "update", "lsn": "101" },
                "value": {
                    "id": "art_sync_1",
                    "slug": "electric-shape-streaming-live",
                    "title": "Electric Shape Streaming Live (Updated)",
                    "description": "Real-time CDC synced into local SQLite",
                    "body": "Updated content.",
                    "author_id": "user_electric",
                    "created_at": "2026-09-14T17:00:00.000Z",
                    "updated_at": "2026-09-14T17:05:00.000Z"
                }
            }
        """.trimIndent().replace("\n", "")

        qjsEngine.evaluateJs<Any?>("__electricClient.applyMessage('article', ['id'], JSON.parse('$updateMsg'))")

        val updatedOffset = qjsEngine.evaluateJs<String>("__electricClient.getOffset('article')")
        assertEquals("1_1", updatedOffset)

        val updatedResult = qjsEngine.evaluateJs<String>("JSON.stringify(__omnishellStorage.sql.query('SELECT title FROM article WHERE id = ?;', ['art_sync_1']))")
        assertTrue(updatedResult.contains("Electric Shape Streaming Live (Updated)"))
    }

    @Test
    fun testElectricShapeClientAppliesDeleteMessages() = runBlocking {
        val qjsEngine = app.engine as com.pronto.omnishell.QuickJsOmnishellEngine

        // Initial check: art_3 exists
        val before = qjsEngine.evaluateJs<String>("JSON.stringify(__omnishellStorage.sql.query('SELECT id FROM article WHERE id = ?;', ['art_3']))")
        assertTrue(before.contains("art_3"))

        // Apply delete message
        val deleteMsg = """
            {
                "key": "art_3",
                "offset": "2_0",
                "headers": { "operation": "delete", "lsn": "102" },
                "value": { "id": "art_3" }
            }
        """.trimIndent().replace("\n", "")

        qjsEngine.evaluateJs<Any?>("__electricClient.applyMessage('article', ['id'], JSON.parse('$deleteMsg'))")

        val after = qjsEngine.evaluateJs<String>("JSON.stringify(__omnishellStorage.sql.query('SELECT id FROM article WHERE id = ?;', ['art_3']))")
        assertEquals("[]", after)

        val offset = qjsEngine.evaluateJs<String>("__electricClient.getOffset('article')")
        assertEquals("2_0", offset)
    }

    private inline fun <reified T> com.pronto.omnishell.QuickJsOmnishellEngine.evaluateJs(script: String): T {
        // Access evaluate via reflection on QuickJS instance or execute via dispatch
        val field = this.javaClass.getDeclaredField("quickJs")
        field.isAccessible = true
        val qjs = field.get(this) as com.dokar.quickjs.QuickJs
        return kotlinx.coroutines.runBlocking {
            qjs.evaluate<T>(script)
        }
    }
}
