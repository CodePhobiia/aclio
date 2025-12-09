import Foundation
import Combine

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
    
    // MARK: - Published State
    @Published var goalText: String = ""
    @Published var dueDate: Date?
    @Published var selectedIconIndex: Int = 0
    @Published var selectedColorIndex: Int = 0
    
    @Published var isLoading: Bool = false
    @Published var isQuestionsLoading: Bool = false
    @Published var error: String?
    
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
        !goalText.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
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
    
    // MARK: - Actions
    
    func selectSuggestion(_ suggestion: String) {
        goalText = suggestion
    }
    
    func generateQuestions() async {
        guard canSubmit else { return }
        
        isQuestionsLoading = true
        showQuestions = true
        error = nil
        
        do {
            let response = try await apiService.generateQuestions(goal: goalText, profile: profile)
            questions = response.questions
            
            // If no questions returned, show a message
            if questions.isEmpty {
                error = "Couldn't generate questions. Try creating your goal directly!"
                showQuestions = false
            }
        } catch let apiError {
            print("Failed to generate questions: \(apiError)")
            error = "Failed to connect: \(apiError.localizedDescription)"
            showQuestions = false
        }
        
        isQuestionsLoading = false
    }
    
    func updateAnswer(for question: String, answer: String) {
        answers[question] = answer
    }
    
    func createGoal() async -> Goal? {
        guard canSubmit else { return nil }
        
        isLoading = true
        error = nil
        startStepAnimation()
        
        // Build additional context from answers
        var additionalContext: String?
        if !answers.isEmpty {
            additionalContext = answers
                .filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
                .map { "\($0.key): \($0.value)" }
                .joined(separator: "\n")
        }
        
        do {
            let response = try await apiService.generateSteps(
                goal: goalText,
                profile: profile,
                location: location,
                additionalContext: additionalContext
            )
            
            // Create the goal
            let isFirstGoal = storage.loadGoals().isEmpty
            
            let newGoal = Goal(
                name: goalText,
                category: response.category,
                iconKey: GoalIcons.keys[selectedIconIndex],
                iconColor: IconColor.options[selectedColorIndex],
                dueDate: dueDate,
                steps: response.toSteps()
            )
            
            // Save
            var goals = storage.loadGoals()
            goals.insert(newGoal, at: 0)
            storage.saveGoals(goals)
            
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
            error = apiError.localizedDescription
            stopStepAnimation()
            isLoading = false
            return nil
        }
    }
    
    func reset() {
        goalText = ""
        dueDate = nil
        selectedIconIndex = 0
        selectedColorIndex = 0
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

