package com.pronto.realworld

import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.junit.jupiter.api.AfterEach
import org.junit.jupiter.api.BeforeEach
import org.junit.jupiter.api.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class RealWorldServerTest {
    private lateinit var server: RealWorldServer
    private val client = OkHttpClient()
    private val port = 8089

    @BeforeEach
    fun setUp() {
        server = RealWorldServer(port = port)
        server.start()
    }

    @AfterEach
    fun tearDown() {
        server.close()
    }

    @Test
    fun testRootEndpointReturnsPreviewHtml() {
        val req = Request.Builder().url("http://localhost:$port/").get().build()
        client.newCall(req).execute().use { res ->
            assertEquals(200, res.code)
            assertEquals("text/html; charset=utf-8", res.header("Content-Type"))
            val body = res.body?.string().orEmpty()
            assertTrue(body.contains("Omnishell-on-Native"))
            assertTrue(body.contains("dist/browser/client.js"))
        }
    }

    @Test
    fun testRootHeadEndpointReturnsHeadersOnly() {
        val req = Request.Builder().url("http://localhost:$port/").head().build()
        client.newCall(req).execute().use { res ->
            assertEquals(200, res.code)
            assertEquals("text/html; charset=utf-8", res.header("Content-Type"))
        }
    }

    @Test
    fun testAstEndpointReturnsDivKitJson() {
        val req = Request.Builder().url("http://localhost:$port/api/ast").get().build()
        client.newCall(req).execute().use { res ->
            assertEquals(200, res.code)
            assertEquals("application/json; charset=utf-8", res.header("Content-Type"))
            val body = res.body?.string().orEmpty()
            assertTrue(body.contains("conduit_realworld_sdui"))
        }
    }

    @Test
    fun testActionDispatchUpdatesAst() {
        val dispatchReq = Request.Builder()
            .url("http://localhost:$port/api/action?uri=pronto%3A%2F%2Fevent%2FSELECT_TAG%3Ftag%3Ddivkit")
            .post("".toRequestBody())
            .build()
        client.newCall(dispatchReq).execute().use { res ->
            assertEquals(200, res.code)
            assertTrue(res.body?.string().orEmpty().contains("\"status\":\"dispatched\""))
        }

        // Allow QuickJS coroutine to process
        Thread.sleep(100)

        val astReq = Request.Builder().url("http://localhost:$port/api/ast").get().build()
        client.newCall(astReq).execute().use { res ->
            val body = res.body?.string().orEmpty()
            assertTrue(body.contains("divkit"))
        }
    }
}
