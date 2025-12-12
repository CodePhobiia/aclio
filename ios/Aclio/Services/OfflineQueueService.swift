import Foundation
import Network
import Combine

// MARK: - Offline Operation Types
enum OfflineOperationType: String, Codable {
    case createGoal
    case updateGoal
    case deleteGoal
    case toggleStep
    case extendGoal
}

// MARK: - Offline Operation
struct OfflineOperation: Identifiable, Codable {
    let id: UUID
    let type: OfflineOperationType
    let payload: Data
    let createdAt: Date
    var retryCount: Int
    
    init(type: OfflineOperationType, payload: Data) {
        self.id = UUID()
        self.type = type
        self.payload = payload
        self.createdAt = Date()
        self.retryCount = 0
    }
}

// MARK: - Network Monitor
@MainActor
final class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    @Published private(set) var isConnected: Bool = true
    @Published private(set) var connectionType: ConnectionType = .unknown
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.aclio.networkmonitor")
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        return .unknown
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Offline Queue Service
@MainActor
final class OfflineQueueService: ObservableObject {
    static let shared = OfflineQueueService()
    
    @Published private(set) var pendingOperations: [OfflineOperation] = []
    @Published private(set) var isProcessing: Bool = false
    
    private let storage = UserDefaults.standard
    private let storageKey = "aclio_offline_queue"
    private let maxRetries = 3
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadQueue()
        observeNetwork()
    }
    
    // MARK: - Network Observation
    
    private func observeNetwork() {
        NetworkMonitor.shared.$isConnected
            .dropFirst() // Skip initial value
            .filter { $0 } // Only when connected
            .sink { [weak self] _ in
                Task {
                    await self?.processQueue()
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Queue Management
    
    func enqueue(_ operation: OfflineOperation) {
        pendingOperations.append(operation)
        saveQueue()
        
        // Try to execute immediately if online
        if NetworkMonitor.shared.isConnected {
            Task {
                await processQueue()
            }
        }
    }
    
    func enqueueGoalToggleStep(goalId: Int, stepId: Int) {
        let payload: [String: Int] = ["goalId": goalId, "stepId": stepId]
        guard let data = try? encoder.encode(payload) else { return }
        
        let operation = OfflineOperation(type: .toggleStep, payload: data)
        enqueue(operation)
    }
    
    func enqueueGoalUpdate(_ goal: Goal) {
        guard let data = try? encoder.encode(goal) else { return }
        
        let operation = OfflineOperation(type: .updateGoal, payload: data)
        enqueue(operation)
    }
    
    func enqueueGoalDelete(goalId: Int) {
        guard let data = try? encoder.encode(["goalId": goalId]) else { return }
        
        let operation = OfflineOperation(type: .deleteGoal, payload: data)
        enqueue(operation)
    }
    
    // MARK: - Queue Processing
    
    func processQueue() async {
        guard !isProcessing else { return }
        guard NetworkMonitor.shared.isConnected else { return }
        guard !pendingOperations.isEmpty else { return }
        
        isProcessing = true
        
        var processedIds: Set<UUID> = []
        var failedOperations: [OfflineOperation] = []
        
        for operation in pendingOperations {
            do {
                try await executeOperation(operation)
                processedIds.insert(operation.id)
            } catch {
                var failedOp = operation
                failedOp.retryCount += 1
                
                if failedOp.retryCount < maxRetries {
                    failedOperations.append(failedOp)
                } else {
                    // Max retries reached, log and discard
                    print("⚠️ OfflineQueue: Discarding operation after \(maxRetries) retries: \(operation.type)")
                }
            }
        }
        
        // Update queue with only failed operations that can be retried
        pendingOperations = failedOperations
        saveQueue()
        
        isProcessing = false
    }
    
    private func executeOperation(_ operation: OfflineOperation) async throws {
        // These operations are local-only for now
        // In a full implementation, you'd sync with a backend here
        switch operation.type {
        case .toggleStep:
            // Local operation - already handled by LocalStorageService
            // This is a placeholder for future sync functionality
            break
            
        case .updateGoal:
            // Local operation - already handled by LocalStorageService
            break
            
        case .deleteGoal:
            // Local operation - already handled by LocalStorageService
            break
            
        case .createGoal:
            // Would sync new goal to server
            break
            
        case .extendGoal:
            // Would sync extended goal to server
            break
        }
    }
    
    // MARK: - Persistence
    
    private func saveQueue() {
        if let data = try? encoder.encode(pendingOperations) {
            storage.set(data, forKey: storageKey)
        }
    }
    
    private func loadQueue() {
        guard let data = storage.data(forKey: storageKey),
              let operations = try? decoder.decode([OfflineOperation].self, from: data) else {
            return
        }
        pendingOperations = operations
    }
    
    func clearQueue() {
        pendingOperations = []
        storage.removeObject(forKey: storageKey)
    }
    
    // MARK: - Status
    
    var hasPendingOperations: Bool {
        !pendingOperations.isEmpty
    }
    
    var pendingCount: Int {
        pendingOperations.count
    }
}

// MARK: - Offline-Aware Goal Operations Extension

extension LocalStorageService {
    /// Save goal with offline queue support
    func saveGoalOfflineAware(_ goal: Goal) {
        // Save locally first
        var goals = loadGoals()
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        } else {
            goals.insert(goal, at: 0)
        }
        saveGoals(goals)
        
        // Queue for sync if offline (NetworkMonitor is @MainActor in Swift 6)
        Task { @MainActor in
            if !NetworkMonitor.shared.isConnected {
                OfflineQueueService.shared.enqueueGoalUpdate(goal)
            }
        }
    }
    
    /// Delete goal with offline queue support
    func deleteGoalOfflineAware(_ goalId: Int) {
        var goals = loadGoals()
        goals.removeAll { $0.id == goalId }
        saveGoals(goals)
        
        // Queue for sync if offline (NetworkMonitor is @MainActor in Swift 6)
        Task { @MainActor in
            if !NetworkMonitor.shared.isConnected {
                OfflineQueueService.shared.enqueueGoalDelete(goalId: goalId)
            }
        }
    }
}

