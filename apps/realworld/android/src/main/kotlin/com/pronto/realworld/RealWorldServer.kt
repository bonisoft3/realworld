package com.pronto.realworld

import com.sun.net.httpserver.HttpExchange
import com.sun.net.httpserver.HttpHandler
import com.sun.net.httpserver.HttpServer
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.net.InetSocketAddress
import java.net.URLDecoder
import java.nio.charset.StandardCharsets
import java.util.concurrent.CopyOnWriteArrayList

class RealWorldServer(
    val port: Int = 8080,
    val app: RealWorldNativeApp = RealWorldNativeApp()
) : AutoCloseable {
    private val server: HttpServer = HttpServer.create(InetSocketAddress(port), 0)
    private val scope = CoroutineScope(Dispatchers.Default)
    private val sseClients = CopyOnWriteArrayList<HttpExchange>()

    init {
        app.start()

        server.createContext("/", RootHandler(app))
        server.createContext("/api/ast", AstHandler(app))
        server.createContext("/api/action", ActionHandler(app))
        server.createContext("/api/stream", SseStreamHandler(sseClients, app))

        // Observe uiAst flow and broadcast to all connected SSE clients
        scope.launch {
            app.uiAst.collect { ast ->
                broadcastAst(ast)
            }
        }
    }

    fun start() {
        server.start()
        println("Omnishell RealWorld Server running at http://localhost:$port")
    }

    private fun broadcastAst(ast: String) {
        val payload = "event: ast\ndata: ${ast.replace("\n", "")}\n\n".toByteArray(StandardCharsets.UTF_8)
        val deadClients = mutableListOf<HttpExchange>()
        for (client in sseClients) {
            try {
                client.responseBody.write(payload)
                client.responseBody.flush()
            } catch (e: Exception) {
                deadClients.add(client)
            }
        }
        sseClients.removeAll(deadClients)
    }

    override fun close() {
        server.stop(0)
        app.close()
    }

    class RootHandler(private val app: RealWorldNativeApp) : HttpHandler {
        override fun handle(exchange: HttpExchange) {
            if (exchange.requestMethod != "GET" && exchange.requestMethod != "HEAD") {
                exchange.sendResponseHeaders(405, -1)
                return
            }

            val html = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Omnishell RealWorld · Native SDUI Preview</title>
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/@divkitframework/divkit@33.2.0/dist/client.css">
    <style>
        :root {
            --bg: #FBFAF7;
            --surface: #FFFFFF;
            --ink: #16181A;
            --secondary: #6B7076;
            --accent: #1D6A4F;
            --border: #E4E1D9;
        }
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background-color: #F0EFEA;
            color: var(--ink);
            min-height: 100vh;
            display: flex;
            flex-direction: column;
        }
        header {
            background: var(--surface);
            border-bottom: 1px solid var(--border);
            padding: 12px 24px;
            display: flex;
            align-items: center;
            justify-content: space-between;
        }
        .header-title {
            font-weight: 700;
            font-size: 16px;
            display: flex;
            align-items: center;
            gap: 8px;
        }
        .badge {
            background: var(--accent);
            color: white;
            font-size: 11px;
            font-weight: 600;
            padding: 2px 8px;
            border-radius: 999px;
            text-transform: uppercase;
            letter-spacing: 0.5px;
        }
        .status-dot {
            width: 8px;
            height: 8px;
            background: #27AE60;
            border-radius: 50%;
            display: inline-block;
        }
        main {
            display: flex;
            flex: 1;
            padding: 24px;
            gap: 24px;
            max-width: 1400px;
            margin: 0 auto;
            width: 100%;
        }
        .preview-pane {
            flex: 0 0 420px;
            display: flex;
            flex-direction: column;
            align-items: center;
        }
        .device-frame {
            width: 412px;
            min-height: 800px;
            background: var(--bg);
            border-radius: 36px;
            border: 10px solid #2C3033;
            box-shadow: 0 20px 40px rgba(0,0,0,0.15);
            overflow: hidden;
            display: flex;
            flex-direction: column;
            position: relative;
        }
        .device-notch {
            height: 28px;
            background: #2C3033;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .device-camera {
            width: 12px;
            height: 12px;
            border-radius: 50%;
            background: #111;
        }
        .device-screen {
            flex: 1;
            overflow-y: auto;
            background: var(--bg);
        }
        .inspector-pane {
            flex: 1;
            background: var(--surface);
            border: 1px solid var(--border);
            border-radius: 12px;
            display: flex;
            flex-direction: column;
            overflow: hidden;
            box-shadow: 0 4px 12px rgba(0,0,0,0.05);
        }
        .inspector-header {
            padding: 12px 16px;
            border-bottom: 1px solid var(--border);
            background: #FAFAFA;
            display: flex;
            justify-content: space-between;
            align-items: center;
            font-size: 13px;
            font-weight: 600;
        }
        .inspector-content {
            flex: 1;
            padding: 16px;
            overflow-y: auto;
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
            font-size: 12px;
            line-height: 1.5;
            background: #1E1E1E;
            color: #D4D4D4;
        }
        .log-section {
            height: 160px;
            border-top: 1px solid var(--border);
            padding: 12px 16px;
            background: #FDFDFD;
            overflow-y: auto;
            font-family: monospace;
            font-size: 12px;
        }
        .log-entry { margin-bottom: 4px; }
        .log-action { color: var(--accent); font-weight: bold; }
    </style>
</head>
<body>
    <header>
        <div class="header-title">
            <span>Omnishell-on-Native</span>
            <span class="badge">RealWorld DivKit SDUI</span>
        </div>
        <div style="display:flex; align-items:center; gap:8px; font-size:13px; color:var(--secondary);">
            <span class="status-dot"></span>
            <span>Live QuickJS Host</span>
        </div>
    </header>

    <main>
        <div class="preview-pane">
            <div class="device-frame">
                <div class="device-notch"><div class="device-camera"></div></div>
                <div id="divkit-root" class="device-screen"></div>
            </div>
            <div style="margin-top:12px; font-size:12px; color:var(--secondary); text-align:center;">
                Jetpack Compose + DivKit SDUI Projection
            </div>
        </div>

        <div class="inspector-pane">
            <div class="inspector-header">
                <span>Live DivKit JSON AST (Server-Driven UI)</span>
                <span id="ast-stat" style="font-weight:normal; color:var(--secondary);">Connecting...</span>
            </div>
            <pre id="ast-json" class="inspector-content">// Waiting for AST emission...</pre>
            <div class="log-section">
                <div style="font-weight:bold; margin-bottom:6px; color:#555;">Action Stream (DivKit → QuickJS)</div>
                <div id="action-log"></div>
            </div>
        </div>
    </main>

    <script src="https://cdn.jsdelivr.net/npm/@divkitframework/divkit@33.2.0/dist/browser/client.js"></script>
    <script>
        const rootElem = document.getElementById('divkit-root');
        const astJsonElem = document.getElementById('ast-json');
        const astStatElem = document.getElementById('ast-stat');
        const actionLogElem = document.getElementById('action-log');

        function logAction(actionUrl) {
            const row = document.createElement('div');
            row.className = 'log-entry';
            const time = new Date().toLocaleTimeString();
            row.innerHTML = `<span style="color:#888;">[${'$'}{time}]</span> Action: <span class="log-action">${'$'}{actionUrl}</span>`;
            actionLogElem.prepend(row);
        }

        function createDivDom(node) {
            if (!node) return document.createElement('div');
            let el;
            if (node.type === 'text') {
                el = document.createElement('div');
                el.textContent = node.text || '';
                if (node.font_size) el.style.fontSize = node.font_size + 'px';
                if (node.font_weight === 'bold') el.style.fontWeight = '700';
                else if (node.font_weight === 'medium') el.style.fontWeight = '500';
                if (node.font_family === 'serif') el.style.fontFamily = "Georgia, Cambria, 'Times New Roman', serif";
                else el.style.fontFamily = "-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif";
                if (node.text_color) el.style.color = node.text_color;
                if (node.max_lines) {
                    el.style.display = '-webkit-box';
                    el.style.webkitLineClamp = node.max_lines;
                    el.style.webkitBoxOrient = 'vertical';
                    el.style.overflow = 'hidden';
                }
            } else if (node.type === 'separator') {
                el = document.createElement('div');
                el.style.backgroundColor = (node.delimiter_style && node.delimiter_style.color) || '#E4E1D9';
                if (node.width && node.width.type === 'flex') {
                    el.style.flex = (node.width.value || 1) + ' 1 0px';
                } else {
                    el.style.height = ((node.height && node.height.value) || 1) + 'px';
                    el.style.width = '100%';
                }
            } else if (node.type === 'gallery') {
                el = document.createElement('div');
                el.style.display = 'flex';
                el.style.flexDirection = 'row';
                el.style.overflowX = 'auto';
                el.style.gap = '8px';
                el.style.webkitOverflowScrolling = 'touch';
                if (node.items) {
                    for (const child of node.items) {
                        el.appendChild(createDivDom(child));
                    }
                }
            } else {
                el = document.createElement('div');
                el.style.display = 'flex';
                el.style.flexDirection = node.orientation === 'horizontal' ? 'row' : 'column';
                if (node.items) {
                    for (const child of node.items) {
                        el.appendChild(createDivDom(child));
                    }
                }
            }

            el.style.boxSizing = 'border-box';

            if (node.paddings) {
                if (node.paddings.top != null) el.style.paddingTop = node.paddings.top + 'px';
                if (node.paddings.bottom != null) el.style.paddingBottom = node.paddings.bottom + 'px';
                if (node.paddings.left != null) el.style.paddingLeft = node.paddings.left + 'px';
                if (node.paddings.right != null) el.style.paddingRight = node.paddings.right + 'px';
            }
            if (node.margins) {
                if (node.margins.top != null) el.style.marginTop = node.margins.top + 'px';
                if (node.margins.bottom != null) el.style.marginBottom = node.margins.bottom + 'px';
                if (node.margins.left != null) el.style.marginLeft = node.margins.left + 'px';
                if (node.margins.right != null) el.style.marginRight = node.margins.right + 'px';
            }
            if (node.background && Array.isArray(node.background)) {
                for (const bg of node.background) {
                    if (bg.type === 'solid' && bg.color) el.style.backgroundColor = bg.color;
                }
            }
            if (node.border) {
                if (node.border.corner_radius) el.style.borderRadius = node.border.corner_radius + 'px';
                if (node.border.stroke) {
                    el.style.border = (node.border.stroke.width || 1) + 'px solid ' + (node.border.stroke.color || '#E4E1D9');
                }
            }
            if (node.width) {
                if (node.width.type === 'flex') el.style.flex = (node.width.value || 1) + ' 1 0px';
                else if (node.width.type === 'match_parent') el.style.width = '100%';
            }
            if (node.alignment_vertical === 'center') el.style.alignSelf = 'center';
            if (node.actions && node.actions.length > 0) {
                el.style.cursor = 'pointer';
                el.setAttribute('role', 'button');
                el.addEventListener('click', function(e) {
                    e.stopPropagation();
                    for (const act of node.actions) {
                        if (act && act.url) {
                            logAction(act.url);
                            fetch('/api/action?uri=' + encodeURIComponent(act.url), { method: 'POST' });
                        }
                    }
                });
            }
            return el;
        }

        function fallbackRender(ast) {
            rootElem.innerHTML = '';
            const card = ast && ast.card;
            if (!card || !card.states || !card.states[0] || !card.states[0].div) {
                rootElem.innerHTML = '<div style="padding:20px; color:#666;">No DivKit card found</div>';
                return;
            }
            const dom = createDivDom(card.states[0].div);
            rootElem.appendChild(dom);
        }

        function renderAst(astString) {
            try {
                const parsed = JSON.parse(astString);
                astJsonElem.textContent = JSON.stringify(parsed, null, 2);
                astStatElem.textContent = `Size: ${'$'}{astString.length} bytes · Valid SDUI AST`;

                rootElem.innerHTML = '';
                let renderedWithDivKit = false;

                if (window.Ya && (window.Ya.DivKit || window.Ya.Divkit)) {
                    const dk = window.Ya.DivKit || window.Ya.Divkit;
                    try {
                        dk.render({
                            id: 'conduit_card',
                            target: rootElem,
                            json: parsed,
                            onCustomAction: function(action) {
                                if (action && action.url) {
                                    logAction(action.url);
                                    fetch('/api/action?uri=' + encodeURIComponent(action.url), { method: 'POST' });
                                }
                            },
                            onError: function(err) {
                                console.warn("DivKit onError callback:", err);
                                if (rootElem.children.length === 0) {
                                    fallbackRender(parsed);
                                }
                            }
                        });
                        if (rootElem.children.length > 0) {
                            renderedWithDivKit = true;
                        }
                    } catch (e) {
                        console.warn("DivKit render threw exception:", e);
                    }
                }

                if (!renderedWithDivKit) {
                    fallbackRender(parsed);
                }
            } catch (e) {
                astJsonElem.textContent = 'AST Parse Error: ' + e.message + '\n\n' + astString;
            }
        }

        // Fetch initial AST
        fetch('/api/ast')
            .then(r => r.text())
            .then(ast => renderAst(ast));

        // Connect SSE live stream
        const sse = new EventSource('/api/stream');
        sse.addEventListener('ast', (e) => {
            renderAst(e.data);
        });
        sse.onerror = () => {
            astStatElem.textContent = 'Stream Reconnecting...';
        };
    </script>
</body>
</html>
            """.trimIndent()

            val bytes = html.toByteArray(StandardCharsets.UTF_8)
            exchange.responseHeaders.set("Content-Type", "text/html; charset=utf-8")
            if (exchange.requestMethod == "HEAD") {
                exchange.sendResponseHeaders(200, -1)
                exchange.responseBody.close()
                return
            }
            exchange.sendResponseHeaders(200, bytes.size.toLong())
            exchange.responseBody.use { it.write(bytes) }
        }
    }

    class AstHandler(private val app: RealWorldNativeApp) : HttpHandler {
        override fun handle(exchange: HttpExchange) {
            if (exchange.requestMethod != "GET" && exchange.requestMethod != "HEAD") {
                exchange.sendResponseHeaders(405, -1)
                return
            }
            val ast = app.uiAst.value
            val bytes = ast.toByteArray(StandardCharsets.UTF_8)
            exchange.responseHeaders.set("Content-Type", "application/json; charset=utf-8")
            if (exchange.requestMethod == "HEAD") {
                exchange.sendResponseHeaders(200, -1)
                exchange.responseBody.close()
                return
            }
            exchange.sendResponseHeaders(200, bytes.size.toLong())
            exchange.responseBody.use { it.write(bytes) }
        }
    }

    class ActionHandler(private val app: RealWorldNativeApp) : HttpHandler {
        override fun handle(exchange: HttpExchange) {
            val rawQuery = exchange.requestURI.rawQuery.orEmpty()
            var uriParam = rawQuery.split("&")
                .firstOrNull { it.startsWith("uri=") }
                ?.substringAfter("uri=")

            if (uriParam == null && exchange.requestMethod == "POST") {
                val body = exchange.requestBody.bufferedReader(StandardCharsets.UTF_8).readText()
                uriParam = body.split("&")
                    .firstOrNull { it.startsWith("uri=") }
                    ?.substringAfter("uri=") ?: body.trim().takeIf { it.startsWith("pronto://") }
            }

            if (uriParam != null) {
                val decoded = URLDecoder.decode(uriParam, StandardCharsets.UTF_8.name())
                app.dispatchAction(decoded)
                val response = "{\"status\":\"dispatched\",\"action\":\"$decoded\"}"
                val bytes = response.toByteArray(StandardCharsets.UTF_8)
                exchange.responseHeaders.set("Content-Type", "application/json")
                exchange.sendResponseHeaders(200, bytes.size.toLong())
                exchange.responseBody.use { it.write(bytes) }
            } else {
                exchange.sendResponseHeaders(400, -1)
            }
        }
    }

    class SseStreamHandler(
        private val clients: CopyOnWriteArrayList<HttpExchange>,
        private val app: RealWorldNativeApp
    ) : HttpHandler {
        override fun handle(exchange: HttpExchange) {
            exchange.responseHeaders.set("Content-Type", "text/event-stream")
            exchange.responseHeaders.set("Cache-Control", "no-cache")
            exchange.responseHeaders.set("Connection", "keep-alive")
            exchange.responseHeaders.set("Access-Control-Allow-Origin", "*")
            exchange.sendResponseHeaders(200, 0) // chunked response

            // Send initial state immediately
            val initialPayload = "event: ast\ndata: ${app.uiAst.value.replace("\n", "")}\n\n".toByteArray(StandardCharsets.UTF_8)
            exchange.responseBody.write(initialPayload)
            exchange.responseBody.flush()

            clients.add(exchange)
        }
    }
}

fun main() {
    val server = RealWorldServer(port = 8080)
    server.start()
    println("Press Ctrl+C to stop.")
    Thread.currentThread().join()
}
