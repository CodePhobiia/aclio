import Foundation

// MARK: - Migration Protocol
protocol Migration {
    var version: Int { get }
    var description: String { get }
    func migrate() throws
}

// MARK: - Migration Error
enum MigrationError: LocalizedError {
    case migrationFailed(version: Int, reason: String)
    case dataCorrupted
    case rollbackFailed
    
    var errorDescription: String? {
        switch self {
        case .migrationFailed(let version, let reason):
            return "Migration to version \(version) failed: \(reason)"
        case .dataCorrupted:
            return "Data is corrupted and cannot be migrated"
        case .rollbackFailed:
            return "Failed to rollback after migration error"
        }
    }
}

// MARK: - Data Migration Service
final class DataMigrationService {
    static let shared = DataMigrationService()
    
    private let defaults = UserDefaults.standard
    private let versionKey = "aclio_data_version"
    
    /// Current schema version - increment when adding new migrations
    private let currentVersion = 2
    
    private init() {}
    
    // MARK: - Version Management
    
    var lastMigrationVersion: Int {
        get { defaults.integer(forKey: versionKey) }
        set { defaults.set(newValue, forKey: versionKey) }
    }
    
    var needsMigration: Bool {
        lastMigrationVersion < currentVersion
    }
    
    // MARK: - Run Migrations
    
    func runMigrationsIfNeeded() throws {
        guard needsMigration else {
            print("📦 DataMigration: Already at version \(currentVersion), no migration needed")
            return
        }
        
        print("📦 DataMigration: Running migrations from v\(lastMigrationVersion) to v\(currentVersion)")
        
        // Backup current data before migration
        let backup = createBackup()
        
        do {
            for version in (lastMigrationVersion + 1)...currentVersion {
                if let migration = migrationForVersion(version) {
                    print("📦 DataMigration: Running migration v\(version) - \(migration.description)")
                    try migration.migrate()
                    lastMigrationVersion = version
                    print("✅ DataMigration: Completed migration v\(version)")
                }
            }
        } catch {
            print("❌ DataMigration: Migration failed, attempting rollback")
            restoreBackup(backup)
            throw error
        }
        
        print("✅ DataMigration: All migrations completed successfully")
    }
    
    // MARK: - Migration Factory
    
    private func migrationForVersion(_ version: Int) -> Migration? {
        switch version {
        case 1: return MigrationV1()
        case 2: return MigrationV2()
        default: return nil
        }
    }
    
    // MARK: - Backup & Restore
    
    private func createBackup() -> [String: Any] {
        var backup: [String: Any] = [:]
        
        let keysToBackup = [
            "aclio_goals",
            "aclio_profile",
            "aclio_points",
            "aclio_streak",
            "aclio_achievements",
            "aclio_expanded_steps"
        ]
        
        for key in keysToBackup {
            if let value = defaults.object(forKey: key) {
                backup[key] = value
            }
        }
        
        return backup
    }
    
    private func restoreBackup(_ backup: [String: Any]) {
        for (key, value) in backup {
            defaults.set(value, forKey: key)
        }
    }
    
    // MARK: - Reset (for testing)
    
    func resetMigrationVersion() {
        lastMigrationVersion = 0
    }
}

// MARK: - Migration V1: Initial Schema
/// Sets up initial schema version tracking
struct MigrationV1: Migration {
    var version: Int { 1 }
    var description: String { "Initial schema setup" }
    
    func migrate() throws {
        // V1 is the baseline - no actual migration needed
        // This just marks that we're tracking versions now
    }
}

// MARK: - Migration V2: Add Goal Metadata
/// Adds new fields to existing goals
struct MigrationV2: Migration {
    var version: Int { 2 }
    var description: String { "Add metadata fields to goals" }
    
    private let defaults = UserDefaults.standard
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()
    
    func migrate() throws {
        // Load existing goals
        guard let data = defaults.data(forKey: "aclio_goals") else {
            // No goals to migrate
            return
        }
        
        // Try to decode with current schema
        // If it works, data is already compatible
        if let _ = try? decoder.decode([Goal].self, from: data) {
            // Goals are already in new format
            return
        }
        
        // If we get here, we need to migrate the data
        // For now, the Goal struct handles missing fields with defaults
        // so we just need to re-encode to ensure compatibility
        
        // Try to decode as a flexible dictionary structure
        guard let goals = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
            throw MigrationError.dataCorrupted
        }
        
        // Migrate each goal, adding any missing fields
        var migratedGoals: [[String: Any]] = []
        
        for var goal in goals {
            // Ensure required fields exist with defaults
            if goal["createdAt"] == nil {
                goal["createdAt"] = Date().timeIntervalSinceReferenceDate
            }
            
            if goal["completedSteps"] == nil {
                goal["completedSteps"] = [Int]()
            }
            
            if goal["iconKey"] == nil {
                goal["iconKey"] = "target"
            }
            
            if goal["iconColor"] == nil {
                goal["iconColor"] = [
                    "name": "Orange",
                    "primary": "#FF6B35",
                    "secondary": "#FFE5DB"
                ]
            }
            
            migratedGoals.append(goal)
        }
        
        // Save migrated data
        guard let newData = try? JSONSerialization.data(withJSONObject: migratedGoals) else {
            throw MigrationError.migrationFailed(version: version, reason: "Failed to serialize migrated goals")
        }
        
        defaults.set(newData, forKey: "aclio_goals")
    }
}

// MARK: - Future Migration Template
/*
struct MigrationV3: Migration {
    var version: Int { 3 }
    var description: String { "Description of what this migration does" }
    
    func migrate() throws {
        // 1. Load existing data
        // 2. Transform to new format
        // 3. Save transformed data
        // 4. Throw MigrationError if something goes wrong
    }
}
*/

// MARK: - App Delegate Integration Helper
extension DataMigrationService {
    /// Call this on app launch to ensure migrations run
    func runOnAppLaunch() {
        do {
            try runMigrationsIfNeeded()
        } catch {
            print("❌ DataMigration: Critical error - \(error.localizedDescription)")
            // In production, you might want to:
            // 1. Log to crash reporting
            // 2. Show user a recovery option
            // 3. Reset to clean state as last resort
        }
    }
}

