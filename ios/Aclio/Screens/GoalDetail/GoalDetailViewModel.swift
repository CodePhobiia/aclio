import Foundation
import Combine

// MARK: - Goal Detail View Model
@MainActor
final class GoalDetailViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let storage = LocalStorageService.shared
    private let apiService = ApiService.shared
    private let gamification = GamificationService.shared
    private let premium = PremiumService.shared
    
    // MARK: - Published State
    @Published var goal: Goal
    @Published var expandedSteps: [String: String] = [:] // "goalId-stepId" -> content
    @Published var expandingStepId: Int?
    @Published var doingItForMeStepId: Int?
    @Published var showCelebration: Bool = false
    @Published var error: String?
    
    // MARK: - Premium
    var isPremium: Bool { premium.isPremium }
    var showPaywall: Bool {
        get { premium.showPaywall }
        set { premium.showPaywall = newValue }
    }
    
    // MARK: - Computed
    var profile: UserProfile? {
        storage.loadProfile()
    }
    
    var progress: Int {
        goal.progress
    }
    
    // MARK: - Initialization
    init(goal: Goal) {
        self.goal = goal
        loadExpandedSteps()
    }
    
    // MARK: - Load Expanded Steps from Cache
    private func loadExpandedSteps() {
        for step in goal.steps {
            if let content = storage.loadExpandedStep(goalId: goal.id, stepId: step.id) {
                expandedSteps["\(goal.id)-\(step.id)"] = content
            }
        }
    }
    
    // MARK: - Toggle Step
    func toggleStep(_ stepId: Int) {
        let wasCompleted = goal.isStepCompleted(stepId)
        goal.toggleStep(stepId)
        saveGoal()
        
        // Award points if completing
        if !wasCompleted {
            gamification.awardStepPoints()
            
            // Check for goal completion
            if goal.isCompleted {
                showCelebration = true
                gamification.awardGoalPoints()
            }
            
            _ = gamification.checkAchievements(goals: storage.loadGoals())
        }
    }
    
    // MARK: - Expand Step
    func expandStep(_ step: Step) async {
        // Check premium
        guard premium.usePremiumFeature(.expandStep) else {
            print("⚠️ Expand blocked by premium check")
            return
        }
        
        expandingStepId = step.id
        error = nil
        
        do {
            print("📡 Calling expand API for step: \(step.title)")
            let response = try await apiService.expandStep(
                step: step,
                goalName: goal.name,
                profile: profile
            )
            
            print("✅ Expand response: \(response.content.prefix(50))...")
            let key = "\(goal.id)-\(step.id)"
            expandedSteps[key] = response.content
            storage.saveExpandedStep(goalId: goal.id, stepId: step.id, content: response.content)
            
        } catch let apiError {
            print("❌ Expand failed: \(apiError)")
            self.error = "Failed to expand: \(apiError.localizedDescription)"
        }
        
        expandingStepId = nil
    }
    
    // MARK: - Do It For Me
    func doItForMe(_ step: Step) async {
        // Check premium
        guard premium.usePremiumFeature(.doItForMe) else {
            print("⚠️ DoItForMe blocked by premium check")
            return
        }
        
        doingItForMeStepId = step.id
        error = nil
        
        do {
            print("📡 Calling doItForMe API for step: \(step.title)")
            let response = try await apiService.doItForMe(
                step: step,
                goalName: goal.name,
                profile: profile
            )
            
            print("✅ DoItForMe response: \(response.displayContent.prefix(50))...")
            // Mark step as completed
            toggleStep(step.id)
            
        } catch let apiError {
            print("❌ DoItForMe failed: \(apiError)")
            self.error = "Failed: \(apiError.localizedDescription)"
        }
        
        doingItForMeStepId = nil
    }
    
    // MARK: - Delete Goal
    func deleteGoal() {
        var goals = storage.loadGoals()
        goals.removeAll { $0.id == goal.id }
        storage.saveGoals(goals)
    }
    
    // MARK: - Helpers
    private func saveGoal() {
        var goals = storage.loadGoals()
        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
            storage.saveGoals(goals)
        }
    }
    
    func getExpandedContent(for stepId: Int) -> String? {
        expandedSteps["\(goal.id)-\(stepId)"]
    }
    
    func dismissCelebration() {
        showCelebration = false
    }
}

