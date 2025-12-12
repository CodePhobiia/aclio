import Foundation
import Combine

// MARK: - Plan Frequency
enum PlanFrequency: String, CaseIterable, Identifiable {
    case daily = "Daily"
    case weekly = "Weekly"
    case monthly = "Monthly"
    case any = "Any"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .daily: return "sun.max.fill"
        case .weekly: return "calendar.badge.clock"
        case .monthly: return "calendar"
        case .any: return "sparkles"
        }
    }
    
    var description: String {
        switch self {
        case .daily: return "Small daily tasks"
        case .weekly: return "Weekly milestones"
        case .monthly: return "Monthly goals"
        case .any: return "AI decides best"
        }
    }
    
    var apiValue: String {
        switch self {
        case .daily: return "daily"
        case .weekly: return "weekly"
        case .monthly: return "monthly"
        case .any: return "any"
        }
    }
}

// MARK: - Generation Step
struct GenerationStep: Identifiable {
    let id: Int
    let text: String
    
    static let all: [GenerationStep] = [
        GenerationStep(id: 1, text: "Understanding your goal"),
        GenerationStep(id: 2, text: "Researching best practices"),
        GenerationStep(id: 3, text: "Creating action steps"),
        GenerationStep(id: 4, text: "Optimizing your timeline"),
        GenerationStep(id: 5, text: "Finalizing your plan"),
    ]
}

// MARK: - New Goal View Model
@MainActor
final class NewGoalViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let storage = LocalStorageService.shared
    private let apiService = ApiService.shared
    private let gamification = GamificationService.shared
    private let analytics = AnalyticsService.shared
    private let crashReporting = CrashReportingService.shared
    private let notifications = NotificationService.shared
    
    // MARK: - Published State
    @Published var goalText: String = ""
    @Published var dueDate: Date?
    @Published var selectedIconIndex: Int = 0
    @Published var selectedColorIndex: Int = 0
    @Published var selectedPlanFrequency: PlanFrequency = .any
    
    @Published var isLoading: Bool = false
    @Published var isQuestionsLoading: Bool = false
    @Published var error: AppError?
    @Published var validationError: String?
    
    @Published var questions: [GenerateQuestionsResponse.ApiQuestion] = []
    @Published var answers: [String: String] = [:]
    @Published var showQuestions: Bool = false
    
    @Published var animatedStep: Int = 0
    
    // MARK: - Computed
    var profile: UserProfile? {
        storage.loadProfile()
    }
    
    var location: LocationData? {
        storage.loadLocation()
    }
    
    var canSubmit: Bool {
        let validation = InputValidator.validateGoal(goalText)
        return validation.isValid && !isLoading
    }
    
    // MARK: - Validation
    func validateGoalInput() -> Bool {
        let validation = InputValidator.validateGoal(goalText)
        validationError = validation.errorMessage
        return validation.isValid
    }
    
    var progressPercent: Double {
        if isLoading {
            return min(Double(animatedStep) / 5.0 * 100, 80)
        }
        return animatedStep == 5 ? 100 : 0
    }
    
    var currentGenerationMessage: String {
        guard animatedStep > 0 && animatedStep <= GenerationStep.all.count else {
            return "Preparing your personalized action plan..."
        }
        return GenerationStep.all[animatedStep - 1].text
    }
    
    var suggestions: [String] {
        ["Learn a new language", "Run a marathon", "Start a side business", "Read 20 books this year"]
    }
    
    // MARK: - Timer
    private var stepTimer: Timer?
    
    // MARK: - Cleanup
    deinit {
        stepTimer?.invalidate()
        stepTimer = nil
    }
    
    // MARK: - Actions
    
    func selectSuggestion(_ suggestion: String) {
        goalText = suggestion
    }
    
    func generateQuestions() async {
        guard validateGoalInput() else { return }
        guard !isLoading else { return }
        
        isQuestionsLoading = true
        showQuestions = true
        error = nil
        validationError = nil
        
        do {
            let response = try await apiService.generateQuestions(goal: goalText, profile: profile)
            questions = response.questions
            
            // If no questions returned, show a message
            if questions.isEmpty {
                error = .serverError("Couldn't generate questions. Try creating your goal directly!")
                showQuestions = false
            }
        } catch let apiError {
            print("Failed to generate questions: \(apiError)")
            error = AppError.from(apiError)
            showQuestions = false
        }
        
        isQuestionsLoading = false
    }
    
    func updateAnswer(for question: String, answer: String) {
        answers[question] = answer
    }
    
    func createGoal() async -> Goal? {
        guard validateGoalInput() else { return nil }
        guard !isLoading else { return nil }
        
        isLoading = true
        error = nil
        validationError = nil
        startStepAnimation()
        
        // Build additional context from answers and frequency preference
        var contextParts: [String] = []
        
        // Add plan frequency preference
        if selectedPlanFrequency != .any {
            contextParts.append("Plan Frequency Preference: \(selectedPlanFrequency.rawValue) tasks - The user wants their action steps broken down into \(selectedPlanFrequency.rawValue.lowercased()) tasks.")
        }
        
        // Add question answers
        if !answers.isEmpty {
            let answersText = answers
                .filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { "\($0.key): \($0.value)" }
                .joined(separator: "\n")
            if !answersText.isEmpty {
                contextParts.append(answersText)
            }
        }
        
        let additionalContext: String? = contextParts.isEmpty ? nil : contextParts.joined(separator: "\n\n")
        
        do {
            let response = try await apiService.generateSteps(
                goal: goalText,
                profile: profile,
                location: location,
                additionalContext: additionalContext
            )
            
            // Create the goal
            let isFirstGoal = storage.loadGoals().isEmpty
            
            // Safe index access for icon and color
            let safeIconIndex = min(selectedIconIndex, GoalIcons.keys.count - 1)
            let safeColorIndex = min(selectedColorIndex, IconColor.options.count - 1)
            
            let newGoal = Goal(
                name: goalText,
                category: response.category,
                iconKey: GoalIcons.keys[max(0, safeIconIndex)],
                iconColor: IconColor.options[max(0, safeColorIndex)],
                dueDate: dueDate,
                steps: response.toSteps()
            )
            
            // Save
            var goals = storage.loadGoals()
            goals.insert(newGoal, at: 0)
            storage.saveGoals(goals)
            
            // Track analytics
            analytics.trackGoalCreated(goalId: newGoal.id, goalName: newGoal.name, category: newGoal.category)
            crashReporting.addBreadcrumb("Goal created: \(newGoal.name)")
            
            // Schedule notifications for due date
            if newGoal.dueDate != nil {
                notifications.scheduleGoalReminders(for: newGoal)
            }
            
            // Award points
            if isFirstGoal {
                gamification.awardGoalPoints(isFirstGoal: true)
            }
            _ = gamification.checkAchievements(goals: goals)
            
            // Complete animation
            completeStepAnimation()
            
            isLoading = false
            return newGoal
            
        } catch let apiError {
            error = AppError.from(apiError)
            crashReporting.recordError(apiError, context: ["action": "create_goal", "goal": goalText])
            analytics.trackError(AppError.from(apiError), context: "create_goal")
            stopStepAnimation()
            isLoading = false
            return nil
        }
    }
    
    // MARK: - Retry
    func retryCreateGoal() async -> Goal? {
        error = nil
        return await createGoal()
    }
    
    func reset() {
        goalText = ""
        dueDate = nil
        selectedIconIndex = 0
        selectedColorIndex = 0
        selectedPlanFrequency = .any
        questions = []
        answers = [:]
        showQuestions = false
        error = nil
        animatedStep = 0
    }
    
    // MARK: - Animation
    
    private func startStepAnimation() {
        animatedStep = 1
        
        stepTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self = self else {
                    timer.invalidate()
                    return
                }
                
                if self.animatedStep < 4 {
                    self.animatedStep += 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
    
    private func completeStepAnimation() {
        stepTimer?.invalidate()
        stepTimer = nil
        animatedStep = 5
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            animatedStep = 0
        }
    }
    
    private func stopStepAnimation() {
        stepTimer?.invalidate()
        stepTimer = nil
        animatedStep = 0
    }
}

