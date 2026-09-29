// RealWorld Conduit Omnishell Native Bundle (Phase 2)
// Full 12-Table Normalized Relational Schema, ElectricSQL Shape Client, and DivKit SDUI Projection

(function() {
    "use strict";

    // Design Tokens from DESIGN.md ("Press")
    const THEME = {
        primary: "#16181A",
        secondary: "#6B7076",
        accent: "#1D6A4F",
        danger: "#A93226",
        neutral: "#FBFAF7",
        surface: "#FFFFFF",
        border: "#E4E1D9",
        surfaceMuted: "#EFEDE6"
    };

    // Client Session State (UI Routing & Filters)
    let state = {
        currentUserId: "user_jessie",
        screen: "home", // "home" | "article" | "profile"
        tab: "global",  // "global" | "feed" | "bookmarks" | "tag"
        selectedTag: null,
        searchQuery: "",
        selectedArticleSlug: null,
        selectedProfileHandle: null
    };

    // ─────────────────────────────────────────────────────────────────────────────
    // 1. ElectricSQL Shape Protocol Client
    // ─────────────────────────────────────────────────────────────────────────────
    class ElectricShapeClient {
        constructor(storage, options) {
            this.storage = storage;
            this.baseUrl = (options && options.baseUrl) || "/electric/v1/shapes";
            this.subscriptions = new Map();
        }

        getOffset(table) {
            if (!this.storage || !this.storage.kv) return "-1";
            return this.storage.kv.get("electric_offset_" + table) || "-1";
        }

        setOffset(table, offset) {
            if (this.storage && this.storage.kv) {
                this.storage.kv.set("electric_offset_" + table, String(offset));
            }
        }

        applyMessage(table, pkColumns, msg) {
            if (!msg || !msg.headers || !this.storage || !this.storage.sql) return;
            const op = msg.headers.operation;
            const val = msg.value;

            if (op === "insert" || op === "update") {
                if (!val) return;
                const cols = Object.keys(val);
                const placeholders = cols.map(() => "?").join(", ");
                const colNames = cols.join(", ");
                const sql = `INSERT OR REPLACE INTO ${table} (${colNames}) VALUES (${placeholders});`;
                const params = cols.map(c => val[c]);
                this.storage.sql.exec(sql, params);
            } else if (op === "delete") {
                const whereClauses = pkColumns.map(col => `${col} = ?`).join(" AND ");
                const params = pkColumns.map(col => (val && val[col]) || msg.key);
                const sql = `DELETE FROM ${table} WHERE ${whereClauses};`;
                this.storage.sql.exec(sql, params);
            }

            if (msg.offset != null) {
                this.setOffset(table, msg.offset);
            }
        }

        applyBatch(table, pkColumns, messages) {
            for (const msg of messages) {
                this.applyMessage(table, pkColumns, msg);
            }
        }

        subscribeLive(table, pkColumns, shapeUrl, onUpdate) {
            const offset = this.getOffset(table);
            const fullUrl = `${shapeUrl || (this.baseUrl + "?table=" + table)}&live=true&live_sse=true&offset=${encodeURIComponent(offset)}`;
            if (typeof EventSource === "undefined") return null;

            const es = new EventSource(fullUrl);
            es.onmessage = (event) => {
                const data = JSON.parse(event.data);
                if (Array.isArray(data)) {
                    this.applyBatch(table, pkColumns, data);
                } else {
                    this.applyMessage(table, pkColumns, data);
                }
                if (onUpdate) onUpdate(table);
            };
            this.subscriptions.set(table, es);
            return es;
        }

        close() {
            for (const [_, es] of this.subscriptions) {
                es.close();
            }
            this.subscriptions.clear();
        }
    }

    const electricClient = typeof __omnishellStorage !== "undefined"
        ? new ElectricShapeClient(__omnishellStorage)
        : null;

    globalThis.__electricClient = electricClient;

    // ─────────────────────────────────────────────────────────────────────────────
    // 2. Normalized 12-Table Schema Alignment (apps/realworld/program.cue)
    // ─────────────────────────────────────────────────────────────────────────────
    function initNormalizedSchema() {
        if (typeof __omnishellStorage === "undefined" || !__omnishellStorage.sql) return;
        const sql = __omnishellStorage.sql;

        sql.exec("CREATE TABLE IF NOT EXISTS app_user (" +
            "id TEXT PRIMARY KEY, handle TEXT UNIQUE, display_name TEXT, bio TEXT, image_url TEXT, created_at TEXT);");

        sql.exec("CREATE TABLE IF NOT EXISTS me (" +
            "id TEXT PRIMARY KEY, handle TEXT);");

        sql.exec("CREATE TABLE IF NOT EXISTS article (" +
            "id TEXT PRIMARY KEY, slug TEXT UNIQUE, title TEXT, description TEXT, body TEXT, author_id TEXT, created_at TEXT, updated_at TEXT);");

        sql.exec("CREATE TABLE IF NOT EXISTS article_tag (" +
            "article_id TEXT, tag TEXT, PRIMARY KEY (article_id, tag));");

        sql.exec("CREATE TABLE IF NOT EXISTS comment (" +
            "id TEXT PRIMARY KEY, article_id TEXT, author_id TEXT, body TEXT, created_at TEXT);");

        sql.exec("CREATE TABLE IF NOT EXISTS favorite (" +
            "user_id TEXT, article_id TEXT, deleted_at TEXT, txid INTEGER, PRIMARY KEY (user_id, article_id));");

        sql.exec("CREATE TABLE IF NOT EXISTS bookmark (" +
            "user_id TEXT, article_id TEXT, created_at TEXT, PRIMARY KEY (user_id, article_id));");

        sql.exec("CREATE TABLE IF NOT EXISTS follow (" +
            "follower_id TEXT, followed_id TEXT, PRIMARY KEY (follower_id, followed_id));");

        sql.exec("CREATE TABLE IF NOT EXISTS article_stats (" +
            "article_id TEXT PRIMARY KEY, favorites_count INTEGER, comments_count INTEGER);");

        sql.exec("CREATE TABLE IF NOT EXISTS tag_count (" +
            "tag TEXT PRIMARY KEY, count INTEGER);");

        sql.exec("CREATE TABLE IF NOT EXISTS favorite_index (" +
            "user_id TEXT, article_id TEXT, created_at TEXT, PRIMARY KEY (user_id, article_id));");

        sql.exec("CREATE TABLE IF NOT EXISTS favorite_count (" +
            "user_id TEXT, article_id TEXT, count INTEGER, PRIMARY KEY (user_id, article_id));");
    }

    function seedNormalizedData() {
        if (typeof __omnishellStorage === "undefined" || !__omnishellStorage.sql) return;
        const sql = __omnishellStorage.sql;

        const check = sql.query("SELECT COUNT(*) as c FROM app_user;");
        if (check && check.length > 0 && check[0].c > 0) return;

        // Seed App Users
        const users = [
            ["user_jessie", "jessie", "Jessie", "Building local-first mobile software.", "https://api.realworld.io/images/smiley-cyrus.jpg", "2026-09-01T00:00:00.000Z"],
            ["user_davi", "davi", "Davi", "Architecting Pronto & Omnishell", "https://api.realworld.io/images/demo-avatar.png", "2026-09-01T00:00:00.000Z"],
            ["user_press", "press", "Press", "The Conduit Editorial Guild", "https://api.realworld.io/images/demo-avatar.png", "2026-09-01T00:00:00.000Z"],
            ["user_electric", "electric", "Electric", "Real-time sync pioneers", "https://api.realworld.io/images/demo-avatar.png", "2026-09-01T00:00:00.000Z"]
        ];
        for (const u of users) {
            sql.exec("INSERT OR REPLACE INTO app_user (id, handle, display_name, bio, image_url, created_at) VALUES (?, ?, ?, ?, ?, ?);", u);
        }

        // Seed Current User Session (me)
        sql.exec("INSERT OR REPLACE INTO me (id, handle) VALUES ('user_jessie', 'jessie');");

        // Seed Articles
        const articles = [
            [
                "art_1", "how-to-build-local-first-pronto-divkit",
                "How to Build a Local-First App with Pronto and DivKit",
                "Isomorphic TypeScript logic in QuickJS with pure native Jetpack Compose SDUI rendering.",
                "Local-first software combines the responsiveness of client-side computing with the durability of distributed data. By running business logic inside QuickJS and projecting native DivKit ASTs, we achieve 100% native UI with zero WebViews.",
                "user_davi", "2026-09-14T10:00:00.000Z", "2026-09-14T10:00:00.000Z"
            ],
            [
                "art_2", "the-type-duality-of-conduit",
                "The Type Duality of Conduit",
                "Serif for authored prose, sans for app chrome: why typographic hierarchy beats color clutter.",
                "Conduit is an editorial ground. Authored words carry serif type, giving prose dignity and reading measure. Metadata, tags, dates, and buttons sit in crisp sans.",
                "user_press", "2026-09-13T14:30:00.000Z", "2026-09-13T14:30:00.000Z"
            ],
            [
                "art_3", "electricsql-shapes-over-sse",
                "ElectricSQL Shapes over SSE",
                "Streaming real-time relational slices straight to device SQLite databases.",
                "ShapeStream proxies live CDC log records over Server-Sent Events straight into native OkHttp streaming bridges, materializing updates directly into local SQLite.",
                "user_electric", "2026-09-12T08:15:00.000Z", "2026-09-12T08:15:00.000Z"
            ]
        ];
        for (const a of articles) {
            sql.exec("INSERT OR REPLACE INTO article (id, slug, title, description, body, author_id, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?);", a);
        }

        // Seed Article Tags
        const tags = [
            ["art_1", "local-first"], ["art_1", "pronto"], ["art_1", "divkit"],
            ["art_2", "design"], ["art_2", "editorial"], ["art_2", "press"],
            ["art_3", "electricsql"], ["art_3", "sync"], ["art_3", "sqlite"]
        ];
        for (const t of tags) {
            sql.exec("INSERT OR REPLACE INTO article_tag (article_id, tag) VALUES (?, ?);", t);
        }

        // Seed Stats & Counts
        sql.exec("INSERT OR REPLACE INTO article_stats (article_id, favorites_count, comments_count) VALUES ('art_1', 42, 1);");
        sql.exec("INSERT OR REPLACE INTO article_stats (article_id, favorites_count, comments_count) VALUES ('art_2', 128, 0);");
        sql.exec("INSERT OR REPLACE INTO article_stats (article_id, favorites_count, comments_count) VALUES ('art_3', 77, 0);");

        const tagCounts = [
            ["local-first", 1], ["pronto", 1], ["divkit", 1],
            ["design", 1], ["editorial", 1], ["press", 1],
            ["electricsql", 1], ["sync", 1], ["sqlite", 1]
        ];
        for (const tc of tagCounts) {
            sql.exec("INSERT OR REPLACE INTO tag_count (tag, count) VALUES (?, ?);", tc);
        }

        // Seed Follow (Jessie follows Davi)
        sql.exec("INSERT OR REPLACE INTO follow (follower_id, followed_id) VALUES ('user_jessie', 'user_davi');");

        // Seed Favorite (Jessie favorites art_2)
        sql.exec("INSERT OR REPLACE INTO favorite (user_id, article_id, deleted_at, txid) VALUES ('user_jessie', 'art_2', NULL, 1);");

        // Seed Bookmark / Reading List (Jessie bookmarks art_1)
        sql.exec("INSERT OR REPLACE INTO bookmark (user_id, article_id, created_at) VALUES ('user_jessie', 'art_1', '2026-09-14T10:30:00.000Z');");

        // Seed Comment
        sql.exec("INSERT OR REPLACE INTO comment (id, article_id, author_id, body, created_at) VALUES ('comm_1', 'art_1', 'user_press', 'Formal verification of the reducer ensures state transitions are always sound.', '2026-09-14T11:00:00.000Z');");
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 3. Relational Queries & Incremental View Projections
    // ─────────────────────────────────────────────────────────────────────────────
    function getArticles(filterTab, currentUserId, tag, search) {
        if (typeof __omnishellStorage === "undefined" || !__omnishellStorage.sql) return [];
        const sql = __omnishellStorage.sql;

        let query = `
            SELECT a.id, a.slug, a.title, a.description, a.body, a.created_at,
                   u.id as author_id, u.handle as author_handle, u.display_name as author_name, u.image_url as author_image,
                   COALESCE(s.favorites_count, 0) as favorites_count,
                   CASE WHEN f.user_id IS NOT NULL AND f.deleted_at IS NULL THEN 1 ELSE 0 END as favorited,
                   CASE WHEN bm.user_id IS NOT NULL THEN 1 ELSE 0 END as bookmarked,
                   (SELECT GROUP_CONCAT(tag, ',') FROM article_tag WHERE article_id = a.id) as tags_csv
            FROM article a
            JOIN app_user u ON a.author_id = u.id
            LEFT JOIN article_stats s ON a.id = s.article_id
            LEFT JOIN favorite f ON a.id = f.article_id AND f.user_id = ? AND f.deleted_at IS NULL
            LEFT JOIN bookmark bm ON a.id = bm.article_id AND bm.user_id = ?
        `;

        const whereConditions = [];
        const params = [currentUserId, currentUserId];

        if (filterTab === "feed") {
            query += ` JOIN follow fl ON fl.followed_id = u.id AND fl.follower_id = ? `;
            params.push(currentUserId);
        } else if (filterTab === "bookmarks") {
            whereConditions.push("bm.user_id IS NOT NULL");
        } else if (filterTab === "tag" && tag) {
            query += ` JOIN article_tag at ON at.article_id = a.id AND at.tag = ? `;
            params.push(tag);
        }

        if (search && search.trim().length > 0) {
            whereConditions.push("(LOWER(a.title) LIKE ? OR LOWER(a.description) LIKE ? OR LOWER(a.body) LIKE ?)");
            const term = "%" + search.trim().toLowerCase() + "%";
            params.push(term, term, term);
        }

        if (whereConditions.length > 0) {
            query += " WHERE " + whereConditions.join(" AND ");
        }

        query += ` ORDER BY a.created_at DESC;`;

        const rows = sql.query(query, params) || [];
        return rows.map(r => ({
            id: r.id,
            slug: r.slug,
            title: r.title,
            description: r.description,
            body: r.body,
            createdAt: r.created_at,
            author: {
                id: r.author_id,
                username: r.author_handle,
                displayName: r.author_name,
                image: r.author_image
            },
            favoritesCount: Number(r.favorites_count) || 0,
            favorited: Boolean(r.favorited),
            bookmarked: Boolean(r.bookmarked),
            tagList: r.tags_csv ? r.tags_csv.split(",") : []
        }));
    }

    function getArticleDetail(slug, currentUserId) {
        if (typeof __omnishellStorage === "undefined" || !__omnishellStorage.sql) return null;
        const sql = __omnishellStorage.sql;

        const query = `
            SELECT a.id, a.slug, a.title, a.description, a.body, a.created_at,
                   u.id as author_id, u.handle as author_handle, u.display_name as author_name, u.image_url as author_image,
                   COALESCE(s.favorites_count, 0) as favorites_count,
                   CASE WHEN f.user_id IS NOT NULL AND f.deleted_at IS NULL THEN 1 ELSE 0 END as favorited,
                   CASE WHEN bm.user_id IS NOT NULL THEN 1 ELSE 0 END as bookmarked,
                   CASE WHEN fl.follower_id IS NOT NULL THEN 1 ELSE 0 END as following,
                   (SELECT GROUP_CONCAT(tag, ',') FROM article_tag WHERE article_id = a.id) as tags_csv
            FROM article a
            JOIN app_user u ON a.author_id = u.id
            LEFT JOIN article_stats s ON a.id = s.article_id
            LEFT JOIN favorite f ON a.id = f.article_id AND f.user_id = ? AND f.deleted_at IS NULL
            LEFT JOIN bookmark bm ON a.id = bm.article_id AND bm.user_id = ?
            LEFT JOIN follow fl ON fl.followed_id = u.id AND fl.follower_id = ?
            WHERE a.slug = ?
            LIMIT 1;
        `;
        const rows = sql.query(query, [currentUserId, currentUserId, currentUserId, slug]) || [];
        if (rows.length === 0) return null;
        const r = rows[0];
        return {
            id: r.id,
            slug: r.slug,
            title: r.title,
            description: r.description,
            body: r.body,
            createdAt: r.created_at,
            author: {
                id: r.author_id,
                username: r.author_handle,
                displayName: r.author_name,
                image: r.author_image,
                following: Boolean(r.following)
            },
            favoritesCount: Number(r.favorites_count) || 0,
            favorited: Boolean(r.favorited),
            bookmarked: Boolean(r.bookmarked),
            tagList: r.tags_csv ? r.tags_csv.split(",") : []
        };
    }

    function getComments(articleId) {
        if (typeof __omnishellStorage === "undefined" || !__omnishellStorage.sql) return [];
        const sql = __omnishellStorage.sql;

        const query = `
            SELECT c.id, c.body, c.created_at, u.id as author_id, u.handle as author_handle, u.image_url as author_image
            FROM comment c
            JOIN app_user u ON c.author_id = u.id
            WHERE c.article_id = ?
            ORDER BY c.created_at ASC;
        `;
        const rows = sql.query(query, [articleId]) || [];
        return rows.map(r => ({
            id: r.id,
            body: r.body,
            createdAt: r.created_at,
            author: {
                id: r.author_id,
                username: r.author_handle,
                image: r.author_image
            }
        }));
    }

    function getTags() {
        if (typeof __omnishellStorage === "undefined" || !__omnishellStorage.sql) return [];
        const rows = __omnishellStorage.sql.query("SELECT tag, count FROM tag_count ORDER BY count DESC, tag ASC;") || [];
        return rows.map(r => r.tag);
    }

    function getBookmarkCount(currentUserId) {
        if (typeof __omnishellStorage === "undefined" || !__omnishellStorage.sql) return 0;
        const rows = __omnishellStorage.sql.query("SELECT COUNT(*) as c FROM bookmark WHERE user_id = ?;", [currentUserId]) || [];
        return rows.length > 0 ? Number(rows[0].c) : 0;
    }

    function getCurrentUser(currentUserId) {
        if (typeof __omnishellStorage === "undefined" || !__omnishellStorage.sql) return null;
        const rows = __omnishellStorage.sql.query("SELECT id, handle, display_name, bio, image_url FROM app_user WHERE id = ?;", [currentUserId]) || [];
        if (rows.length === 0) return null;
        return {
            id: rows[0].id,
            username: rows[0].handle,
            displayName: rows[0].display_name,
            bio: rows[0].bio,
            image: rows[0].image_url
        };
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 4. Action URI Parser & Pure Jessie Reducer
    // ─────────────────────────────────────────────────────────────────────────────
    function parseActionUri(uri) {
        if (!uri || !uri.startsWith("pronto://event/")) return null;
        const raw = uri.substring("pronto://event/".length);
        const qIdx = raw.indexOf("?");
        if (qIdx === -1) {
            return { action: raw, params: {} };
        }
        const action = raw.substring(0, qIdx);
        const queryStr = raw.substring(qIdx + 1);
        const params = {};
        const pairs = queryStr.split("&");
        for (const pair of pairs) {
            const [k, v] = pair.split("=");
            if (k) {
                const cleanVal = v ? decodeURIComponent(v.replace(/\+/g, " ")) : "";
                params[decodeURIComponent(k)] = cleanVal;
            }
        }
        return { action, params };
    }

    function reduce(currState, actionUri) {
        const parsed = parseActionUri(actionUri);
        if (!parsed) return currState;

        const { action, params } = parsed;
        const next = Object.assign({}, currState);
        const sql = (typeof __omnishellStorage !== "undefined") ? __omnishellStorage.sql : null;

        switch (action) {
            case "SELECT_TAB":
                next.tab = params.tab || "global";
                next.selectedTag = null;
                next.screen = "home";
                break;

            case "SELECT_TAG":
                next.tab = "tag";
                next.selectedTag = params.tag;
                next.screen = "home";
                break;

            case "SEARCH":
                next.searchQuery = params.query || "";
                next.screen = "home";
                break;

            case "NAVIGATE":
                next.screen = params.screen || "home";
                if (params.slug) next.selectedArticleSlug = params.slug;
                if (params.handle) next.selectedProfileHandle = params.handle;
                break;

            case "VIEW_ARTICLE":
                next.screen = "article";
                next.selectedArticleSlug = params.slug;
                break;

            case "PUBLISH_ARTICLE": {
                if (!sql) break;
                const title = params.title || "Untitled Article";
                const desc = params.description || "";
                const body = params.body || "";
                const tagStr = params.tags || "";
                const slug = title.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)/g, '') || ("article-" + Date.now());
                const artId = "art_" + Date.now();
                const now = new Date().toISOString();

                sql.exec(
                    "INSERT OR REPLACE INTO article (id, slug, title, description, body, author_id, created_at, updated_at) VALUES (?, ?, ?, ?, ?, ?, ?, ?);",
                    [artId, slug, title, desc, body, next.currentUserId, now, now]
                );
                sql.exec(
                    "INSERT OR REPLACE INTO article_stats (article_id, favorites_count, comments_count) VALUES (?, 0, 0);",
                    [artId]
                );

                const tagList = tagStr.split(/[,\s]+/).map(t => t.trim().toLowerCase()).filter(t => t.length > 0);
                for (const t of tagList) {
                    sql.exec("INSERT OR IGNORE INTO article_tag (article_id, tag) VALUES (?, ?);", [artId, t]);
                    sql.exec("INSERT INTO tag_count (tag, count) VALUES (?, 1) ON CONFLICT(tag) DO UPDATE SET count = count + 1;", [t]);
                }

                next.screen = "article";
                next.selectedArticleSlug = slug;
                break;
            }

            case "TOGGLE_FAVORITE": {
                if (!sql) break;
                const slug = params.slug;
                const rows = sql.query("SELECT id FROM article WHERE slug = ?;", [slug]) || [];
                if (rows.length > 0) {
                    const artId = rows[0].id;
                    const favs = sql.query("SELECT user_id, deleted_at FROM favorite WHERE user_id = ? AND article_id = ?;", [next.currentUserId, artId]) || [];
                    const isFavorited = favs.length > 0 && favs[0].deleted_at === null;

                    if (isFavorited) {
                        sql.exec("UPDATE favorite SET deleted_at = ? WHERE user_id = ? AND article_id = ?;", [new Date().toISOString(), next.currentUserId, artId]);
                        sql.exec("UPDATE article_stats SET favorites_count = MAX(0, favorites_count - 1) WHERE article_id = ?;", [artId]);
                    } else {
                        sql.exec("INSERT OR REPLACE INTO favorite (user_id, article_id, deleted_at, txid) VALUES (?, ?, NULL, 1);", [next.currentUserId, artId]);
                        sql.exec("UPDATE article_stats SET favorites_count = favorites_count + 1 WHERE article_id = ?;", [artId]);
                    }
                }
                break;
            }

            case "TOGGLE_BOOKMARK": {
                if (!sql) break;
                const slug = params.slug;
                const rows = sql.query("SELECT id FROM article WHERE slug = ?;", [slug]) || [];
                if (rows.length > 0) {
                    const artId = rows[0].id;
                    const bms = sql.query("SELECT user_id FROM bookmark WHERE user_id = ? AND article_id = ?;", [next.currentUserId, artId]) || [];
                    if (bms.length > 0) {
                        sql.exec("DELETE FROM bookmark WHERE user_id = ? AND article_id = ?;", [next.currentUserId, artId]);
                    } else {
                        sql.exec("INSERT OR REPLACE INTO bookmark (user_id, article_id, created_at) VALUES (?, ?, ?);", [next.currentUserId, artId, new Date().toISOString()]);
                    }
                }
                break;
            }

            case "TOGGLE_FOLLOW": {
                if (!sql) break;
                const targetHandle = params.username;
                const userRows = sql.query("SELECT id FROM app_user WHERE handle = ?;", [targetHandle]) || [];
                if (userRows.length > 0) {
                    const targetId = userRows[0].id;
                    if (targetId !== next.currentUserId) {
                        const fl = sql.query("SELECT follower_id FROM follow WHERE follower_id = ? AND followed_id = ?;", [next.currentUserId, targetId]) || [];
                        if (fl.length > 0) {
                            sql.exec("DELETE FROM follow WHERE follower_id = ? AND followed_id = ?;", [next.currentUserId, targetId]);
                        } else {
                            sql.exec("INSERT OR REPLACE INTO follow (follower_id, followed_id) VALUES (?, ?);", [next.currentUserId, targetId]);
                        }
                    }
                }
                break;
            }

            case "ADD_COMMENT": {
                if (!sql) break;
                const slug = params.slug;
                const bodyText = params.body;
                if (bodyText && bodyText.trim().length > 0) {
                    const rows = sql.query("SELECT id FROM article WHERE slug = ?;", [slug]) || [];
                    if (rows.length > 0) {
                        const artId = rows[0].id;
                        const newId = "comm_" + Date.now();
                        sql.exec("INSERT INTO comment (id, article_id, author_id, body, created_at) VALUES (?, ?, ?, ?, ?);",
                            [newId, artId, next.currentUserId, bodyText.trim(), new Date().toISOString()]);
                        sql.exec("UPDATE article_stats SET comments_count = comments_count + 1 WHERE article_id = ?;", [artId]);
                    }
                }
                break;
            }

            case "DELETE_COMMENT": {
                if (!sql) break;
                const commId = params.id;
                const slug = params.slug;
                if (commId) {
                    sql.exec("DELETE FROM comment WHERE id = ? AND author_id = ?;", [commId, next.currentUserId]);
                    if (slug) {
                        const rows = sql.query("SELECT id FROM article WHERE slug = ?;", [slug]) || [];
                        if (rows.length > 0) {
                            sql.exec("UPDATE article_stats SET comments_count = MAX(0, comments_count - 1) WHERE article_id = ?;", [rows[0].id]);
                        }
                    }
                }
                break;
            }

            case "SIGN_IN":
                next.currentUserId = params.userId || "user_jessie";
                if (sql) {
                    sql.exec("INSERT OR REPLACE INTO me (id, handle) VALUES (?, ?);", [next.currentUserId, params.username || "jessie"]);
                }
                break;

            case "SIGN_OUT":
                next.currentUserId = "anon";
                if (sql) {
                    sql.exec("DELETE FROM me;");
                }
                break;
        }

        return next;
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 5. DivKit Server-Driven UI AST Projection
    // ─────────────────────────────────────────────────────────────────────────────
    function projectToDivKit(s) {
        const currentUser = getCurrentUser(s.currentUserId);
        const bookmarkCount = getBookmarkCount(s.currentUserId);
        const tags = getTags();

        // 5.1 App Header
        const headerItems = [
            {
                type: "text",
                text: "conduit",
                font_size: 22,
                font_weight: "bold",
                font_family: "sans-serif",
                text_color: THEME.accent,
                actions: [{ log_id: "nav_home", url: "pronto://event/NAVIGATE?screen=home" }]
            },
            {
                type: "separator",
                width: { type: "flex", value: 1 }
            }
        ];

        if (currentUser) {
            headerItems.push({
                type: "container",
                orientation: "horizontal",
                alignment_vertical: "center",
                items: [
                    {
                        type: "text",
                        text: "★ " + bookmarkCount,
                        font_size: 13,
                        font_weight: "bold",
                        font_family: "sans-serif",
                        text_color: s.tab === "bookmarks" ? THEME.accent : THEME.secondary,
                        paddings: { left: 8, right: 8, top: 4, bottom: 4 },
                        background: [{ type: "solid", color: s.tab === "bookmarks" ? THEME.surfaceMuted : THEME.surface }],
                        border: { corner_radius: 12 },
                        actions: [{ log_id: "nav_bookmarks", url: "pronto://event/SELECT_TAB?tab=bookmarks" }]
                    },
                    {
                        type: "text",
                        text: "✍ New Article",
                        font_size: 13,
                        font_weight: "medium",
                        font_family: "sans-serif",
                        text_color: s.screen === "editor" ? THEME.accent : THEME.secondary,
                        paddings: { left: 8, right: 8, top: 4, bottom: 4 },
                        background: [{ type: "solid", color: s.screen === "editor" ? THEME.surfaceMuted : THEME.surface }],
                        border: { corner_radius: 12 },
                        margins: { left: 6, right: 6 },
                        actions: [{ log_id: "nav_editor", url: "pronto://event/NAVIGATE?screen=editor" }]
                    },
                    {
                        type: "text",
                        text: "@" + currentUser.username,
                        font_size: 14,
                        font_weight: "medium",
                        font_family: "sans-serif",
                        text_color: THEME.primary,
                        margins: { left: 8, right: 8 }
                    },
                    {
                        type: "text",
                        text: "Sign out",
                        font_size: 13,
                        font_family: "sans-serif",
                        text_color: THEME.secondary,
                        actions: [{ log_id: "auth_signout", url: "pronto://event/SIGN_OUT" }]
                    }
                ]
            });
        } else {
            headerItems.push({
                type: "text",
                text: "Sign in as @jessie",
                font_size: 14,
                font_weight: "medium",
                font_family: "sans-serif",
                text_color: THEME.accent,
                actions: [{ log_id: "auth_signin", url: "pronto://event/SIGN_IN?username=jessie&userId=user_jessie" }]
            });
        }

        const navHeader = {
            type: "container",
            orientation: "horizontal",
            paddings: { left: 16, right: 16, top: 14, bottom: 12 },
            background: [{ type: "solid", color: THEME.surface }],
            border: { stroke: { color: THEME.border, width: 1 } },
            items: headerItems
        };

        // 5.2 Screen Projections
        let contentItems = [];

        if (s.screen === "article") {
            const article = getArticleDetail(s.selectedArticleSlug, s.currentUserId);
            if (!article) {
                contentItems.push({
                    type: "text",
                    text: "Article not found.",
                    font_size: 16,
                    font_family: "sans-serif",
                    paddings: { left: 16, right: 16, top: 24, bottom: 24 }
                });
            } else {
                const comments = getComments(article.id);
                const isAuthor = currentUser && currentUser.id === article.author.id;

                contentItems.push({
                    type: "container",
                    orientation: "vertical",
                    paddings: { left: 16, right: 16, top: 16, bottom: 20 },
                    background: [{ type: "solid", color: THEME.surface }],
                    items: [
                        {
                            type: "text",
                            text: "← Back to feed",
                            font_size: 13,
                            font_weight: "medium",
                            font_family: "sans-serif",
                            text_color: THEME.accent,
                            margins: { bottom: 12 },
                            actions: [{ log_id: "back_to_feed", url: "pronto://event/NAVIGATE?screen=home" }]
                        },
                        {
                            type: "text",
                            text: article.title,
                            font_size: 24,
                            font_weight: "bold",
                            font_family: "serif",
                            text_color: THEME.primary,
                            margins: { bottom: 12 }
                        },
                        {
                            type: "container",
                            orientation: "horizontal",
                            alignment_vertical: "center",
                            margins: { bottom: 16 },
                            items: [
                                {
                                    type: "text",
                                    text: "@" + article.author.username,
                                    font_size: 13,
                                    font_weight: "medium",
                                    font_family: "sans-serif",
                                    text_color: THEME.accent,
                                    margins: { right: 12 }
                                },
                                {
                                    type: "separator",
                                    width: { type: "flex", value: 1 }
                                },
                                {
                                    type: "text",
                                    text: article.bookmarked ? "★ Saved" : "☆ Save",
                                    font_size: 12,
                                    font_weight: "medium",
                                    font_family: "sans-serif",
                                    text_color: article.bookmarked ? THEME.accent : THEME.secondary,
                                    paddings: { left: 8, right: 8, top: 4, bottom: 4 },
                                    margins: { right: 8 },
                                    border: { stroke: { color: THEME.border, width: 1 }, corner_radius: 12 },
                                    actions: [{ log_id: "btn_save", url: "pronto://event/TOGGLE_BOOKMARK?slug=" + article.slug }]
                                },
                                (!isAuthor ? {
                                    type: "text",
                                    text: article.author.following ? "✓ Following" : "+ Follow",
                                    font_size: 12,
                                    font_weight: "medium",
                                    font_family: "sans-serif",
                                    text_color: article.author.following ? THEME.surface : THEME.accent,
                                    background: [{ type: "solid", color: article.author.following ? THEME.accent : THEME.surface }],
                                    border: { stroke: { color: THEME.accent, width: 1 }, corner_radius: 12 },
                                    paddings: { left: 8, right: 8, top: 4, bottom: 4 },
                                    margins: { right: 8 },
                                    actions: [{ log_id: "btn_follow", url: "pronto://event/TOGGLE_FOLLOW?username=" + article.author.username }]
                                } : { type: "container", orientation: "horizontal" }),
                                {
                                    type: "text",
                                    text: (article.favorited ? "♥ " : "♡ ") + article.favoritesCount,
                                    font_size: 12,
                                    font_weight: "bold",
                                    font_family: "sans-serif",
                                    text_color: article.favorited ? THEME.accent : THEME.secondary,
                                    border: { stroke: { color: THEME.border, width: 1 }, corner_radius: 12 },
                                    paddings: { left: 8, right: 8, top: 4, bottom: 4 },
                                    actions: [{ log_id: "btn_fav", url: "pronto://event/TOGGLE_FAVORITE?slug=" + article.slug }]
                                }
                            ]
                        },
                        {
                            type: "separator",
                            height: { type: "exact", value: 1 },
                            delimiter_style: { color: THEME.border },
                            margins: { bottom: 16 }
                        },
                        {
                            type: "text",
                            text: article.body,
                            font_size: 16,
                            font_family: "serif",
                            text_color: THEME.primary,
                            margins: { bottom: 20 }
                        }
                    ]
                });

                // Comments Section
                contentItems.push({
                    type: "container",
                    orientation: "vertical",
                    paddings: { left: 16, right: 16, top: 12, bottom: 24 },
                    items: [
                        {
                            type: "text",
                            text: "Comments (" + comments.length + ")",
                            font_size: 15,
                            font_weight: "bold",
                            font_family: "sans-serif",
                            text_color: THEME.primary,
                            margins: { bottom: 12 }
                        },
                        {
                            type: "container",
                            orientation: "horizontal",
                            alignment_vertical: "center",
                            paddings: { left: 12, right: 12, top: 8, bottom: 8 },
                            background: [{ type: "solid", color: THEME.surface }],
                            border: { stroke: { color: THEME.border, width: 1 }, corner_radius: 8 },
                            margins: { bottom: 16 },
                            items: [
                                {
                                    type: "text",
                                    text: "Add a comment: 'Great local-first writeup!'",
                                    font_size: 13,
                                    font_family: "sans-serif",
                                    text_color: THEME.secondary,
                                    actions: [{ log_id: "btn_add_comment", url: "pronto://event/ADD_COMMENT?slug=" + article.slug + "&body=Great+local-first+writeup!" }]
                                }
                            ]
                        }
                    ]
                });

                for (const c of comments) {
                    const isMyComment = currentUser && currentUser.id === c.author.id;
                    contentItems.push({
                        type: "container",
                        orientation: "vertical",
                        paddings: { left: 12, right: 12, top: 10, bottom: 10 },
                        margins: { left: 16, right: 16, bottom: 8 },
                        background: [{ type: "solid", color: THEME.surface }],
                        border: { stroke: { color: THEME.border, width: 1 }, corner_radius: 8 },
                        items: [
                            {
                                type: "text",
                                text: c.body,
                                font_size: 14,
                                font_family: "sans-serif",
                                text_color: THEME.primary,
                                margins: { bottom: 8 }
                            },
                            {
                                type: "container",
                                orientation: "horizontal",
                                alignment_vertical: "center",
                                items: [
                                    {
                                        type: "text",
                                        text: "@" + c.author.username,
                                        font_size: 12,
                                        font_weight: "medium",
                                        font_family: "sans-serif",
                                        text_color: THEME.secondary
                                    },
                                    {
                                        type: "separator",
                                        width: { type: "flex", value: 1 }
                                    },
                                    (isMyComment ? {
                                        type: "text",
                                        text: "✕ Delete",
                                        font_size: 12,
                                        font_family: "sans-serif",
                                        text_color: THEME.danger,
                                        actions: [{ log_id: "del_comment", url: "pronto://event/DELETE_COMMENT?slug=" + article.slug + "&id=" + c.id }]
                                    } : { type: "container", orientation: "horizontal" })
                                ]
                            }
                        ]
                    });
                }
            }
        } else if (s.screen === "editor") {
            contentItems.push({
                type: "container",
                orientation: "vertical",
                paddings: { left: 24, right: 24, top: 24, bottom: 32 },
                background: [{ type: "solid", color: THEME.surface }],
                border: { stroke: { color: THEME.border, width: 1 }, corner_radius: 12 },
                items: [
                    {
                        type: "text",
                        text: "← Back to feed",
                        font_size: 13,
                        font_weight: "medium",
                        font_family: "sans-serif",
                        text_color: THEME.accent,
                        margins: { bottom: 16 },
                        actions: [{ log_id: "back_to_feed", url: "pronto://event/NAVIGATE?screen=home" }]
                    },
                    {
                        type: "text",
                        text: "New Article",
                        font_size: 26,
                        font_weight: "bold",
                        font_family: "serif",
                        text_color: THEME.primary,
                        margins: { bottom: 4 }
                    },
                    {
                        type: "text",
                        text: "Writing as @" + (currentUser ? currentUser.username : "jessie") + " · Synced locally to SQLite",
                        font_size: 13,
                        font_family: "sans-serif",
                        text_color: THEME.secondary,
                        margins: { bottom: 20 }
                    },
                    {
                        type: "input",
                        id: "title",
                        hint_text: "Article Title",
                        font_size: 20,
                        font_weight: "bold",
                        font_family: "serif",
                        text_color: THEME.primary,
                        keyboard_type: "single_line_text",
                        paddings: { left: 14, right: 14, top: 12, bottom: 12 },
                        border: { stroke: { color: THEME.border, width: 1 }, corner_radius: 8 },
                        margins: { bottom: 14 }
                    },
                    {
                        type: "input",
                        id: "description",
                        hint_text: "What's this article about? (A one-line standfirst)",
                        font_size: 15,
                        font_family: "sans-serif",
                        text_color: THEME.primary,
                        keyboard_type: "single_line_text",
                        paddings: { left: 14, right: 14, top: 12, bottom: 12 },
                        border: { stroke: { color: THEME.border, width: 1 }, corner_radius: 8 },
                        margins: { bottom: 14 }
                    },
                    {
                        type: "input",
                        id: "body",
                        hint_text: "Write your piece. Markdown works: # headings, **bold**, > quotes, `code`, - lists.",
                        font_size: 15,
                        font_family: "serif",
                        text_color: THEME.primary,
                        keyboard_type: "multi_line_text",
                        line_count: 8,
                        paddings: { left: 14, right: 14, top: 12, bottom: 12 },
                        border: { stroke: { color: THEME.border, width: 1 }, corner_radius: 8 },
                        margins: { bottom: 14 }
                    },
                    {
                        type: "input",
                        id: "cover_url",
                        hint_text: "Paste a link to a cover image (optional)",
                        font_size: 14,
                        font_family: "sans-serif",
                        text_color: THEME.secondary,
                        keyboard_type: "single_line_text",
                        paddings: { left: 14, right: 14, top: 12, bottom: 12 },
                        border: { stroke: { color: THEME.border, width: 1 }, corner_radius: 8 },
                        margins: { bottom: 14 }
                    },
                    {
                        type: "input",
                        id: "tags",
                        hint_text: "Tags, separated by spaces (e.g. editorial design local-first)",
                        font_size: 14,
                        font_family: "sans-serif",
                        text_color: THEME.secondary,
                        keyboard_type: "single_line_text",
                        paddings: { left: 14, right: 14, top: 12, bottom: 12 },
                        border: { stroke: { color: THEME.border, width: 1 }, corner_radius: 8 },
                        margins: { bottom: 20 }
                    },
                    {
                        type: "container",
                        orientation: "horizontal",
                        alignment_vertical: "center",
                        items: [
                            {
                                type: "separator",
                                width: { type: "flex", value: 1 }
                            },
                            {
                                type: "text",
                                text: "Publish Article",
                                font_size: 14,
                                font_weight: "bold",
                                font_family: "sans-serif",
                                text_color: "#FFFFFF",
                                paddings: { left: 24, right: 24, top: 10, bottom: 10 },
                                background: [{ type: "solid", color: THEME.accent }],
                                border: { corner_radius: 20 },
                                actions: [{ log_id: "publish_submit", url: "pronto://event/PUBLISH_ARTICLE" }]
                            }
                        ]
                    }
                ]
            });
        } else {
            // 5.3 Home Feed View
            const tabConfigs = [
                { id: "global", label: "Global Feed" },
                { id: "feed", label: "Your Feed" },
                { id: "bookmarks", label: "Reading List (" + bookmarkCount + ")" }
            ];
            if (s.selectedTag) {
                tabConfigs.push({ id: "tag", label: "#" + s.selectedTag });
            }

            const tabPills = tabConfigs.map(t => {
                const isActive = (s.tab === t.id);
                return {
                    type: "text",
                    text: t.label,
                    font_size: 13,
                    font_weight: isActive ? "bold" : "regular",
                    font_family: "sans-serif",
                    text_color: isActive ? THEME.accent : THEME.secondary,
                    paddings: { left: 12, right: 12, top: 8, bottom: 8 },
                    margins: { right: 6 },
                    border: {
                        stroke: { color: isActive ? THEME.accent : THEME.border, width: isActive ? 2 : 1 },
                        corner_radius: 16
                    },
                    background: [{ type: "solid", color: isActive ? THEME.surfaceMuted : THEME.surface }],
                    actions: [{
                        log_id: "tab_" + t.id,
                        url: t.id === "tag" ? ("pronto://event/SELECT_TAG?tag=" + s.selectedTag) : ("pronto://event/SELECT_TAB?tab=" + t.id)
                    }]
                };
            });

            // Feed Tabs Container
            contentItems.push({
                type: "container",
                orientation: "horizontal",
                paddings: { left: 16, right: 16, top: 12, bottom: 8 },
                items: tabPills
            });

            // Popular Tag Chips
            const tagChips = tags.map(tag => ({
                type: "text",
                text: "#" + tag,
                font_size: 11,
                font_family: "sans-serif",
                text_color: s.selectedTag === tag ? THEME.surface : THEME.secondary,
                background: [{ type: "solid", color: s.selectedTag === tag ? THEME.accent : THEME.surfaceMuted }],
                paddings: { left: 8, right: 8, top: 4, bottom: 4 },
                margins: { right: 6, bottom: 6 },
                border: { corner_radius: 8 },
                actions: [{ log_id: "chip_" + tag, url: "pronto://event/SELECT_TAG?tag=" + tag }]
            }));

            contentItems.push({
                type: "container",
                orientation: "vertical",
                paddings: { left: 16, right: 16, top: 4, bottom: 8 },
                items: [
                    {
                        type: "text",
                        text: "Popular Tags",
                        font_size: 12,
                        font_weight: "bold",
                        font_family: "sans-serif",
                        text_color: THEME.secondary,
                        margins: { bottom: 6 }
                    },
                    {
                        type: "gallery",
                        orientation: "horizontal",
                        items: tagChips
                    }
                ]
            });

            // Articles Feed
            const articles = getArticles(s.tab, s.currentUserId, s.selectedTag, s.searchQuery);

            if (articles.length === 0) {
                let emptyMsg = "No articles here yet.";
                if (s.tab === "feed") emptyMsg = "Your feed is empty. Follow authors on the Global Feed to see their writing here!";
                else if (s.tab === "bookmarks") emptyMsg = "Your reading list is empty. Tap the ★ button on any article to keep it here.";
                else if (s.tab === "tag") emptyMsg = "No articles tagged #" + s.selectedTag + ".";

                contentItems.push({
                    type: "text",
                    text: emptyMsg,
                    font_size: 14,
                    font_family: "sans-serif",
                    text_color: THEME.secondary,
                    paddings: { left: 16, right: 16, top: 32, bottom: 32 }
                });
            } else {
                for (const a of articles) {
                    const articleTags = a.tagList.map(t => ({
                        type: "text",
                        text: t,
                        font_size: 11,
                        font_family: "sans-serif",
                        text_color: THEME.secondary,
                        paddings: { left: 6, right: 6, top: 2, bottom: 2 },
                        margins: { left: 4 },
                        border: { stroke: { color: THEME.border, width: 1 }, corner_radius: 6 }
                    }));

                    contentItems.push({
                        type: "container",
                        orientation: "vertical",
                        paddings: { left: 16, right: 16, top: 16, bottom: 16 },
                        margins: { left: 12, right: 12, bottom: 10 },
                        background: [{ type: "solid", color: THEME.surface }],
                        border: { stroke: { color: THEME.border, width: 1 }, corner_radius: 12 },
                        items: [
                            {
                                type: "container",
                                orientation: "horizontal",
                                alignment_vertical: "center",
                                margins: { bottom: 8 },
                                items: [
                                    {
                                        type: "text",
                                        text: "@" + a.author.username,
                                        font_size: 13,
                                        font_weight: "medium",
                                        font_family: "sans-serif",
                                        text_color: THEME.accent
                                    },
                                    {
                                        type: "separator",
                                        width: { type: "flex", value: 1 }
                                    },
                                    {
                                        type: "text",
                                        text: a.bookmarked ? "★" : "☆",
                                        font_size: 14,
                                        font_weight: "bold",
                                        font_family: "sans-serif",
                                        text_color: a.bookmarked ? THEME.accent : THEME.secondary,
                                        paddings: { left: 8, right: 8, top: 2, bottom: 2 },
                                        margins: { right: 6 },
                                        actions: [{ log_id: "bm_" + a.slug, url: "pronto://event/TOGGLE_BOOKMARK?slug=" + a.slug }]
                                    },
                                    {
                                        type: "text",
                                        text: (a.favorited ? "♥ " : "♡ ") + a.favoritesCount,
                                        font_size: 12,
                                        font_weight: "bold",
                                        font_family: "sans-serif",
                                        text_color: a.favorited ? THEME.accent : THEME.secondary,
                                        paddings: { left: 6, right: 6, top: 2, bottom: 2 },
                                        border: { stroke: { color: THEME.border, width: 1 }, corner_radius: 8 },
                                        actions: [{ log_id: "fav_" + a.slug, url: "pronto://event/TOGGLE_FAVORITE?slug=" + a.slug }]
                                    }
                                ]
                            },
                            {
                                type: "text",
                                text: a.title,
                                font_size: 17,
                                font_weight: "bold",
                                font_family: "serif",
                                text_color: THEME.primary,
                                margins: { bottom: 4 },
                                actions: [{ log_id: "read_title_" + a.slug, url: "pronto://event/VIEW_ARTICLE?slug=" + a.slug }]
                            },
                            {
                                type: "text",
                                text: a.description,
                                font_size: 13,
                                font_family: "sans-serif",
                                text_color: THEME.secondary,
                                max_lines: 2,
                                margins: { bottom: 10 },
                                actions: [{ log_id: "read_desc_" + a.slug, url: "pronto://event/VIEW_ARTICLE?slug=" + a.slug }]
                            },
                            {
                                type: "container",
                                orientation: "horizontal",
                                alignment_vertical: "center",
                                items: [
                                    {
                                        type: "text",
                                        text: "Read more...",
                                        font_size: 11,
                                        font_weight: "medium",
                                        font_family: "sans-serif",
                                        text_color: THEME.secondary,
                                        actions: [{ log_id: "read_more_" + a.slug, url: "pronto://event/VIEW_ARTICLE?slug=" + a.slug }]
                                    },
                                    {
                                        type: "separator",
                                        width: { type: "flex", value: 1 }
                                    },
                                    {
                                        type: "container",
                                        orientation: "horizontal",
                                        items: articleTags
                                    }
                                ]
                            }
                        ]
                    });
                }
            }
        }

        return {
            card: {
                log_id: "conduit_realworld_sdui",
                states: [
                    {
                        state_id: 0,
                        div: {
                            type: "container",
                            orientation: "vertical",
                            background: [{ type: "solid", color: THEME.neutral }],
                            items: [
                                navHeader,
                                ...contentItems
                            ]
                        }
                    }
                ]
            }
        };
    }

    // ─────────────────────────────────────────────────────────────────────────────
    // 6. Engine Lifecycle Hook & Action Listener Registration
    // ─────────────────────────────────────────────────────────────────────────────
    initNormalizedSchema();
    seedNormalizedData();

    // Emit initial DivKit JSON AST
    emitUiAst(JSON.stringify(projectToDivKit(state)));

    // Register Native Action Dispatcher
    onAction(function(actionUri) {
        state = reduce(state, actionUri);
        emitUiAst(JSON.stringify(projectToDivKit(state)));
    });

})();
