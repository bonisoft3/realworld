import Foundation
import Omnishell

public final class RealWorldNativeApp: @unchecked Sendable {
    public let db: SqlDatabase
    public let kv: KeyValueStore
    public let engine: OmnishellEngine
    public let actionHandler: RealWorldDivActionHandler

    public var uiAst: String {
        engine.uiAst
    }

    public var onAstChanged: ((String) -> Void)? {
        get { engine.onAstChanged }
        set { engine.onAstChanged = newValue }
    }

    public init(dbPath: String = ":memory:", bundleScript: String? = nil) {
        do {
            let sqliteDb = try CSystemSqliteDatabase(path: dbPath)
            self.db = sqliteDb

            let kvStore = try SqliteKeyValueStore(db: sqliteDb)
            self.kv = kvStore

            let storageBridge = StorageBridge(sqlDatabase: sqliteDb, keyValueStore: kvStore)
            let networkBridge = NetworkBridge(client: URLSessionFetchClient())

            let script = bundleScript ?? Self.loadDefaultBundle()

            let jscEngine = JavaScriptCoreOmnishellEngine(
                networkBridge: networkBridge,
                storageBridge: storageBridge,
                initialScript: script
            )
            self.engine = jscEngine
            self.actionHandler = RealWorldDivActionHandler(engine: jscEngine)
        } catch {
            fatalError("Failed to initialize RealWorldNativeApp: \(error)")
        }
    }

    public func start() {
        do {
            try engine.start()
        } catch {
            fatalError("Failed to start RealWorld engine: \(error)")
        }
    }

    public func close() {
        engine.close()
    }

    public func dispatchAction(_ action: String) {
        engine.dispatchAction(action)
    }

    private static func loadDefaultBundle() -> String {
        // Try Bundle.module resource
        if let url = Bundle.module.url(forResource: "realworld_bundle", withExtension: "js") ??
                     Bundle.module.url(forResource: "realworld_bundle", withExtension: "js", subdirectory: "bundle") {
            if let content = try? String(contentsOf: url, encoding: .utf8), !content.isEmpty {
                return content
            }
        }

        // Fallback: resolve relative to file location
        let fileUrl = URL(fileURLWithPath: #filePath)
        let rootBundleUrl = fileUrl
            .deletingLastPathComponent() // Sources/RealWorld
            .deletingLastPathComponent() // Sources
            .deletingLastPathComponent() // apps/realworld/ios
            .appendingPathComponent("bundle/realworld_bundle.js")

        if let content = try? String(contentsOf: rootBundleUrl, encoding: .utf8), !content.isEmpty {
            return content
        }

        fatalError("Could not locate realworld_bundle.js in Bundle.module or package directory")
    }
}
