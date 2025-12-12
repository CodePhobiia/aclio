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
    private let analytics = AnalyticsService.shared
    private let crashReporting = CrashReportingService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published State
    @Published var goal: Goal
    @Published var savedExpandedSteps: Set<Int> = [] // Step IDs that have been saved
    @Published var expandingStepId: Int?
    @Published var doingItForMeStepId: Int?
    @Published var showCelebration: Bool = false
    @Published var error: AppError?
    
    // MARK: - Result Views State
    @Published var showExpandedResult: Bool = false
    @Published var expandedResultStep: Step?
    @Published var expandedResultGuide: String = ""
    @Published var expandedResultTips: [String] = []
    @Published var expandedResultResources: [ExpandResource] = []
    @Published var expandedResultIsSaved: Bool = false
    
    @Published var showDoItForMeResult: Bool = false
    @Published var doItForMeResultStep: Step?
    @Published var doItForMeResultContent: String = ""
    
    // MARK: - Extend Goal State
    @Published var isExtendingGoal: Bool = false
    
    // MARK: - Premium State (forwarded from service)
    @Published var isPremium: Bool = false
    @Published var showPaywall: Bool = false
    
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
        observePremium()
    }
    
    // MARK: - Cleanup
    deinit {
        cancellables.removeAll()
    }
    
    // MARK: - Observe Premium Service
    private func observePremium() {
        premium.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.isPremium = self.premium.isPremium
                self.showPaywall = self.premium.showPaywall
            }
            .store(in: &cancellables)
        
        // Initialize with current values
        isPremium = premium.isPremium
        showPaywall = premium.showPaywall
    }
    
    func dismissPaywall() {
        showPaywall = false
        premium.showPaywall = false
    }
    
    // MARK: - Load Expanded Steps from Cache
    private func loadExpandedSteps() {
        for step in goal.steps {
            if storage.loadExpandedStep(goalId: goal.id, stepId: step.id) != nil {
                savedExpandedSteps.insert(step.id)
            }
        }
    }
    
    func isStepExpanded(_ stepId: Int) -> Bool {
        savedExpandedSteps.contains(stepId)
    }
    
    // MARK: - Toggle Step
    func toggleStep(_ stepId: Int) {
        let wasCompleted = goal.isStepCompleted(stepId)
        goal.toggleStep(stepId)
        saveGoal()
        
        // Track analytics
        if !wasCompleted {
            analytics.trackStepCompleted(goalId: goal.id, stepId: stepId, progress: goal.progress)
            crashReporting.addBreadcrumb("Step completed: \(stepId) in goal \(goal.id)")
        }
        
        // Award points if completing
        if !wasCompleted {
            gamification.awardStepPoints()
            
            // Check for goal completion
            if goal.isCompleted {
                showCelebration = true
                gamification.awardGoalPoints()
                analytics.trackGoalCompleted(goalId: goal.id, goalName: goal.name)
                crashReporting.addBreadcrumb("Goal completed: \(goal.name)")
            }
            
            _ = gamification.checkAchievements(goals: storage.loadGoals())
        }
    }
    
    // MARK: - Expand Step
    func expandStep(_ step: Step) async {
        // Check premium
        guard premium.usePremiumFeature(.expandStep) else {
            print("⚠️ Expand blocked by premium check")
            analytics.trackPaywallViewed(source: "expand_step")
            return
        }
        
        expandingStepId = step.id
        error = nil
        crashReporting.addBreadcrumb("Expanding step: \(step.id)")
        
        do {
            print("📡 Calling expand API for step: \(step.title)")
            let response = try await apiService.expandStep(
                step: step,
                goalName: goal.name,
                profile: profile
            )
            
            print("✅ Expand response received")
            
            // Track analytics
            analytics.trackStepExpanded(goalId: goal.id, stepId: step.id)
            
            // Show the result view with full data
            expandedResultStep = step
            expandedResultGuide = response.detailedGuide ?? ""
            expandedResultTips = response.tips ?? []
            expandedResultResources = response.resources ?? []
            expandedResultIsSaved = false
            expandingStepId = nil
            showExpandedResult = true
            
        } catch let apiError {
            print("❌ Expand failed: \(apiError)")
            self.error = AppError.from(apiError)
            crashReporting.recordError(apiError, context: ["action": "expand_step", "goalId": String(goal.id)])
            expandingStepId = nil
        }
    }
    
    // MARK: - View Saved Expanded Content
    func viewSavedExpand(_ step: Step) {
        guard let content = storage.loadExpandedStep(goalId: goal.id, stepId: step.id) else { return }
        
        // Parse saved content (simple format for now)
        expandedResultStep = step
        expandedResultGuide = content
        expandedResultTips = []
        expandedResultResources = []
        expandedResultIsSaved = true
        showExpandedResult = true
    }
    
    // MARK: - Save Expanded Content
    func saveExpandedContent() {
        guard let step = expandedResultStep else { return }
        
        // Save to storage
        let content = expandedResultGuide
        storage.saveExpandedStep(goalId: goal.id, stepId: step.id, content: content)
        savedExpandedSteps.insert(step.id)
        expandedResultIsSaved = true
    }
    
    // MARK: - Do It For Me
    func doItForMe(_ step: Step) async {
        // Check premium
        guard premium.usePremiumFeature(.doItForMe) else {
            print("⚠️ DoItForMe blocked by premium check")
            analytics.trackPaywallViewed(source: "do_it_for_me")
            return
        }
        
        doingItForMeStepId = step.id
        error = nil
        crashReporting.addBreadcrumb("Do it for me: \(step.id)")
        
        do {
            print("📡 Calling doItForMe API for step: \(step.title)")
            let response = try await apiService.doItForMe(
                step: step,
                goalName: goal.name,
                profile: profile
            )
            
            print("✅ DoItForMe response: \(response.displayContent.prefix(50))...")
            
            // Track analytics
            analytics.trackStepDoItForMe(goalId: goal.id, stepId: step.id)
            
            // Show the result view (don't mark complete yet - let user do it from result view)
            doItForMeResultStep = step
            doItForMeResultContent = response.displayContent
            doingItForMeStepId = nil
            showDoItForMeResult = true
            
        } catch let apiError {
            print("❌ DoItForMe failed: \(apiError)")
            self.error = AppError.from(apiError)
            crashReporting.recordError(apiError, context: ["action": "do_it_for_me", "goalId": String(goal.id)])
            doingItForMeStepId = nil
        }
    }
    
    // MARK: - Dismiss Results
    func dismissExpandedResult() {
        showExpandedResult = false
        expandedResultStep = nil
        expandedResultGuide = ""
        expandedResultTips = []
        expandedResultResources = []
    }
    
    func dismissDoItForMeResult() {
        showDoItForMeResult = false
        doItForMeResultStep = nil
        doItForMeResultContent = ""
    }
    
    func markDoItForMeStepComplete() {
        guard let step = doItForMeResultStep else { return }
        toggleStep(step.id)
    }
    
    // MARK: - Extend Goal
    func extendGoal(additionalContext: String) async {
        isExtendingGoal = true
        error = nil
        
        do {
            // Build context with existing steps and user request
            var context = "Existing steps completed: \(goal.completedStepsCount) of \(goal.totalStepsCount).\n"
            context += "Current steps: \(goal.steps.map { $0.title }.joined(separator: ", ")).\n"
            context += "User request for extension: \(additionalContext)"
            
            print("📡 Extending goal: \(goal.name)")
            let response = try await apiService.generateSteps(
                goal: goal.name,
                profile: profile,
                location: nil,
                additionalContext: context
            )
            
            print("✅ Extension response received with \(response.steps.count) new steps")
            
            // Create new steps with IDs continuing from existing ones
            let maxExistingId = goal.steps.map { $0.id }.max() ?? 0
            let newSteps = response.steps.enumerated().map { index, stepData in
                Step(
                    id: maxExistingId + index + 1,
                    title: stepData.title,
                    description: stepData.description,
                    duration: stepData.duration
                )
            }
            
            // Add new steps to goal
            goal.steps.append(contentsOf: newSteps)
            saveGoal()
            
            // Award points for extending
            gamification.awardStepPoints()
            
            isExtendingGoal = false
            
        } catch let apiError {
            print("❌ Extend goal failed: \(apiError)")
            self.error = AppError.from(apiError)
            isExtendingGoal = false
        }
    }
    
    // MARK: - Retry Methods
    func retryExpandStep(_ step: Step) async {
        error = nil
        await expandStep(step)
    }
    
    func retryDoItForMe(_ step: Step) async {
        error = nil
        await doItForMe(step)
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
    
    
    func dismissCelebration() {
        showCelebration = false
    }
}

