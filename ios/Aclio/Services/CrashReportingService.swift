import Foundation
import UIKit

// MARK: - Crash Report
struct CrashReport: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let type: CrashType
    let message: String
    let stackTrace: String?
    let deviceInfo: DeviceInfo
    let appInfo: AppInfo
    let userContext: [String: String]
    var isReported: Bool
    
    enum CrashType: String, Codable {
        case crash
        case exception
        case error
        case assertion
        case signal
    }
    
    struct DeviceInfo: Codable {
        let model: String
        let osVersion: String
        let locale: String
        let timezone: String
        let isLowPowerMode: Bool
        let availableMemory: UInt64?
    }
    
    struct AppInfo: Codable {
        let version: String
        let buildNumber: String
        let bundleId: String
    }
    
    init(
        type: CrashType,
        message: String,
        stackTrace: String? = nil,
        userContext: [String: String] = [:]
    ) {
        self.id = UUID().uuidString
        self.timestamp = Date()
        self.type = type
        self.message = message
        self.stackTrace = stackTrace
        self.deviceInfo = DeviceInfo(
            model: UIDevice.current.model,
            osVersion: UIDevice.current.systemVersion,
            locale: Locale.current.identifier,
            timezone: TimeZone.current.identifier,
            isLowPowerMode: ProcessInfo.processInfo.isLowPowerModeEnabled,
            availableMemory: CrashReportingService.availableMemory
        )
        self.appInfo = AppInfo(
            version: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            buildNumber: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
            bundleId: Bundle.main.bundleIdentifier ?? "unknown"
        )
        self.userContext = userContext
        self.isReported = false
    }
}

// MARK: - Error Log Entry
struct ErrorLogEntry: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let level: LogLevel
    let message: String
    let file: String
    let function: String
    let line: Int
    let context: [String: String]
    
    enum LogLevel: String, Codable {
        case debug
        case info
        case warning
        case error
        case critical
        
        var emoji: String {
            switch self {
            case .debug: return "🔍"
            case .info: return "ℹ️"
            case .warning: return "⚠️"
            case .error: return "❌"
            case .critical: return "🚨"
            }
        }
    }
}

// MARK: - Crash Reporting Service
/// Handles crash reporting and error logging for the app.
///
/// This service provides local crash/error capture. In production,
/// you would integrate with a service like Firebase Crashlytics,
/// Sentry, or Bugsnag.
///
/// Features:
/// - Crash capture with device info
/// - Error logging with levels
/// - Breadcrumb trail for debugging
/// - Export functionality
///
/// Usage:
/// ```swift
/// // Log an error
/// CrashReportingService.shared.logError("Something went wrong", context: ["userId": "123"])
///
/// // Record a non-fatal error
/// CrashReportingService.shared.recordError(error, context: ["screen": "Dashboard"])
/// ```
@MainActor
final class CrashReportingService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = CrashReportingService()
    
    // MARK: - Configuration
    private let maxReports = 50
    private let maxLogEntries = 500
    private let maxBreadcrumbs = 100
    
    // MARK: - Storage Keys
    private enum StorageKey {
        static let crashReports = "aclio_crash_reports"
        static let errorLogs = "aclio_error_logs"
        static let breadcrumbs = "aclio_breadcrumbs"
        static let userId = "aclio_crash_user_id"
    }
    
    // MARK: - State
    @Published private(set) var crashReports: [CrashReport] = []
    @Published private(set) var errorLogs: [ErrorLogEntry] = []
    @Published private(set) var breadcrumbs: [String] = []
    
    private let storage = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // User context for crash reports
    private var userContext: [String: String] = [:]
    
    // MARK: - Initialization
    
    private init() {
        loadStoredData()
        setupCrashHandlers()
    }
    
    // MARK: - Setup
    
    private func setupCrashHandlers() {
        // Note: In production, you'd use a proper crash reporting SDK
        // This is a basic implementation for demonstration
        
        // Set up exception handler
        NSSetUncaughtExceptionHandler { exception in
            Task { @MainActor in
                CrashReportingService.shared.handleException(exception)
            }
        }
        
        // Set up signal handlers for crashes
        setupSignalHandlers()
    }
    
    private func setupSignalHandlers() {
        // In production, use a proper signal handling mechanism
        // This is simplified for demonstration
        signal(SIGABRT) { _ in
            // Handle abort signal
        }
        signal(SIGSEGV) { _ in
            // Handle segmentation fault
        }
        signal(SIGBUS) { _ in
            // Handle bus error
        }
    }
    
    private func handleException(_ exception: NSException) {
        let stackTrace = exception.callStackSymbols.joined(separator: "\n")
        let report = CrashReport(
            type: .exception,
            message: "\(exception.name.rawValue): \(exception.reason ?? "Unknown")",
            stackTrace: stackTrace,
            userContext: userContext
        )
        
        crashReports.append(report)
        saveCrashReports()
    }
    
    // MARK: - User Context
    
    /// Sets user identifier for crash reports
    func setUserId(_ userId: String?) {
        if let id = userId {
            userContext["userId"] = id
            storage.set(id, forKey: StorageKey.userId)
        } else {
            userContext.removeValue(forKey: "userId")
            storage.removeObject(forKey: StorageKey.userId)
        }
    }
    
    /// Sets a custom key-value for crash context
    func setCustomKey(_ key: String, value: String?) {
        if let value = value {
            userContext[key] = value
        } else {
            userContext.removeValue(forKey: key)
        }
    }
    
    // MARK: - Breadcrumbs
    
    /// Adds a breadcrumb for debugging
    func addBreadcrumb(_ message: String) {
        let timestamped = "[\(ISO8601DateFormatter().string(from: Date()))] \(message)"
        breadcrumbs.append(timestamped)
        
        // Trim if too many
        if breadcrumbs.count > maxBreadcrumbs {
            breadcrumbs.removeFirst(breadcrumbs.count - maxBreadcrumbs)
        }
        
        saveBreadcrumbs()
        
        #if DEBUG
        print("🍞 Breadcrumb: \(message)")
        #endif
    }
    
    // MARK: - Error Logging
    
    /// Logs a debug message
    func debug(
        _ message: String,
        context: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .debug, message: message, context: context, file: file, function: function, line: line)
    }
    
    /// Logs an info message
    func info(
        _ message: String,
        context: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .info, message: message, context: context, file: file, function: function, line: line)
    }
    
    /// Logs a warning message
    func warning(
        _ message: String,
        context: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .warning, message: message, context: context, file: file, function: function, line: line)
    }
    
    /// Logs an error message
    func logError(
        _ message: String,
        context: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .error, message: message, context: context, file: file, function: function, line: line)
    }
    
    /// Logs a critical error
    func critical(
        _ message: String,
        context: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        log(level: .critical, message: message, context: context, file: file, function: function, line: line)
    }
    
    private func log(
        level: ErrorLogEntry.LogLevel,
        message: String,
        context: [String: String],
        file: String,
        function: String,
        line: Int
    ) {
        let fileName = (file as NSString).lastPathComponent
        
        let entry = ErrorLogEntry(
            id: UUID().uuidString,
            timestamp: Date(),
            level: level,
            message: message,
            file: fileName,
            function: function,
            line: line,
            context: context
        )
        
        errorLogs.append(entry)
        
        // Trim if too many
        if errorLogs.count > maxLogEntries {
            errorLogs.removeFirst(errorLogs.count - maxLogEntries)
        }
        
        saveErrorLogs()
        
        // Print in debug mode
        #if DEBUG
        print("\(level.emoji) [\(fileName):\(line)] \(message)")
        #endif
    }
    
    // MARK: - Error Recording
    
    /// Records a non-fatal error
    func recordError(_ error: Error, context: [String: String] = [:]) {
        var fullContext = userContext
        for (key, value) in context {
            fullContext[key] = value
        }
        
        logError(error.localizedDescription, context: fullContext)
        
        // Add to breadcrumbs
        addBreadcrumb("Error: \(error.localizedDescription)")
    }
    
    /// Records an AppError
    func recordAppError(_ error: AppError, context: [String: String] = [:]) {
        var fullContext = userContext
        fullContext["error_type"] = error.id
        for (key, value) in context {
            fullContext[key] = value
        }
        
        logError(error.errorDescription ?? "Unknown error", context: fullContext)
    }
    
    // MARK: - Crash Recording
    
    /// Records a crash (for manual crash recording)
    func recordCrash(type: CrashReport.CrashType, message: String, stackTrace: String? = nil) {
        let report = CrashReport(
            type: type,
            message: message,
            stackTrace: stackTrace,
            userContext: userContext
        )
        
        crashReports.append(report)
        
        // Trim if too many
        if crashReports.count > maxReports {
            crashReports.removeFirst(crashReports.count - maxReports)
        }
        
        saveCrashReports()
    }
    
    // MARK: - Persistence
    
    private func loadStoredData() {
        // Load crash reports
        if let data = storage.data(forKey: StorageKey.crashReports),
           let reports = try? decoder.decode([CrashReport].self, from: data) {
            crashReports = reports
        }
        
        // Load error logs
        if let data = storage.data(forKey: StorageKey.errorLogs),
           let logs = try? decoder.decode([ErrorLogEntry].self, from: data) {
            errorLogs = logs
        }
        
        // Load breadcrumbs
        if let crumbs = storage.stringArray(forKey: StorageKey.breadcrumbs) {
            breadcrumbs = crumbs
        }
        
        // Load user ID
        if let userId = storage.string(forKey: StorageKey.userId) {
            userContext["userId"] = userId
        }
    }
    
    private func saveCrashReports() {
        if let data = try? encoder.encode(crashReports) {
            storage.set(data, forKey: StorageKey.crashReports)
        }
    }
    
    private func saveErrorLogs() {
        if let data = try? encoder.encode(errorLogs) {
            storage.set(data, forKey: StorageKey.errorLogs)
        }
    }
    
    private func saveBreadcrumbs() {
        storage.set(breadcrumbs, forKey: StorageKey.breadcrumbs)
    }
    
    // MARK: - Export
    
    /// Exports all crash data as JSON
    func exportCrashData() -> Data? {
        struct ExportData: Codable {
            let crashReports: [CrashReport]
            let errorLogs: [ErrorLogEntry]
            let breadcrumbs: [String]
            let exportDate: Date
        }
        
        let export = ExportData(
            crashReports: crashReports,
            errorLogs: errorLogs,
            breadcrumbs: breadcrumbs,
            exportDate: Date()
        )
        
        let exportEncoder = JSONEncoder()
        exportEncoder.outputFormatting = .prettyPrinted
        return try? exportEncoder.encode(export)
    }
    
    // MARK: - Cleanup
    
    /// Clears all crash data
    func clearAllData() {
        crashReports.removeAll()
        errorLogs.removeAll()
        breadcrumbs.removeAll()
        
        storage.removeObject(forKey: StorageKey.crashReports)
        storage.removeObject(forKey: StorageKey.errorLogs)
        storage.removeObject(forKey: StorageKey.breadcrumbs)
    }
    
    /// Marks a crash report as reported
    func markReported(_ reportId: String) {
        if let index = crashReports.firstIndex(where: { $0.id == reportId }) {
            crashReports[index].isReported = true
            saveCrashReports()
        }
    }
    
    // MARK: - Memory Info
    
    nonisolated static var availableMemory: UInt64? {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return nil }
        return info.resident_size
    }
}

// MARK: - Convenience Logging Functions
/// Global logging functions for easy access
func logDebug(_ message: String, context: [String: String] = [:], file: String = #file, function: String = #function, line: Int = #line) {
    Task { @MainActor in
        CrashReportingService.shared.debug(message, context: context, file: file, function: function, line: line)
    }
}

func logInfo(_ message: String, context: [String: String] = [:], file: String = #file, function: String = #function, line: Int = #line) {
    Task { @MainActor in
        CrashReportingService.shared.info(message, context: context, file: file, function: function, line: line)
    }
}

func logWarning(_ message: String, context: [String: String] = [:], file: String = #file, function: String = #function, line: Int = #line) {
    Task { @MainActor in
        CrashReportingService.shared.warning(message, context: context, file: file, function: function, line: line)
    }
}

func logError(_ message: String, context: [String: String] = [:], file: String = #file, function: String = #function, line: Int = #line) {
    Task { @MainActor in
        CrashReportingService.shared.logError(message, context: context, file: file, function: function, line: line)
    }
}

