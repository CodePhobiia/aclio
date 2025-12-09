import Foundation
import Combine

// MARK: - Chat Message
struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let role: MessageRole
    var content: String
    let timestamp: Date
    var isStreaming: Bool
    
    enum MessageRole: String {
        case user
        case assistant
    }
    
    init(id: UUID = UUID(), role: MessageRole, content: String, timestamp: Date = Date(), isStreaming: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.isStreaming = isStreaming
    }
}

// MARK: - Chat View Model
@MainActor
final class ChatViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let storage = LocalStorageService.shared
    private let apiService = ApiService.shared
    private let premium = PremiumService.shared
    
    // MARK: - Published State
    @Published var messages: [ChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    
    // MARK: - Properties
    let goal: Goal?
    
    var profile: UserProfile? {
        storage.loadProfile()
    }
    
    var isPremium: Bool { premium.isPremium }
    var showPaywall: Bool {
        get { premium.showPaywall }
        set { premium.showPaywall = newValue }
    }
    
    var quickPrompts: [String] {
        if goal != nil {
            return [
                "Give me motivation",
                "What should I focus on?",
                "How do I stay consistent?",
                "Tips for this step"
            ]
        } else {
            return [
                "Help me set a goal",
                "Give me motivation",
                "How do I stay consistent?",
                "Tips for productivity"
            ]
        }
    }
    
    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespaces).isEmpty && !isLoading
    }
    
    // MARK: - Initialization
    init(goal: Goal?) {
        self.goal = goal
        addWelcomeMessage()
    }
    
    private func addWelcomeMessage() {
        let content: String
        if let goal = goal {
            content = """
            Hi! I'm Aclio, your AI goal coach! 🐰
            
            I see you're working on "\(goal.name)". How can I help you today?
            
            I can:
            • Give you motivation and tips
            • Help break down your next steps
            • Answer questions about your goal
            • Suggest resources and strategies
            """
        } else {
            content = """
            Hi! I'm Aclio, your AI goal coach! 🐰
            
            How can I help you achieve your goals today?
            
            I can:
            • Give you motivation and tips
            • Help you plan your next steps
            • Answer questions
            • Suggest strategies
            """
        }
        
        messages.append(ChatMessage(
            role: .assistant,
            content: content
        ))
    }
    
    // MARK: - Actions
    
    func selectQuickPrompt(_ prompt: String) {
        inputText = prompt
    }
    
    func sendMessage() async {
        guard canSend else { return }
        
        let userMessage = ChatMessage(
            role: .user,
            content: inputText.trimmingCharacters(in: .whitespaces)
        )
        messages.append(userMessage)
        inputText = ""
        
        isLoading = true
        
        // Create placeholder for streaming
        let assistantMessage = ChatMessage(
            role: .assistant,
            content: "",
            isStreaming: true
        )
        messages.append(assistantMessage)
        let assistantIndex = messages.count - 1
        
        // Build chat history
        let chatHistory = messages.dropFirst().dropLast(2).map { message in
            ["role": message.role.rawValue, "content": message.content]
        }
        
        do {
            try await apiService.chatStream(
                message: userMessage.content,
                goal: goal,
                chatHistory: chatHistory,
                profile: profile
            ) { [weak self] chunk in
                guard let self = self else { return }
                self.messages[assistantIndex].content += chunk
            }
            
            // Mark streaming complete
            messages[assistantIndex].isStreaming = false
            
            // Ensure we have content
            if messages[assistantIndex].content.isEmpty {
                messages[assistantIndex].content = "I'm here to help! Could you tell me more?"
            }
            
        } catch {
            messages[assistantIndex].content = "I'm having trouble connecting right now. Please try again in a moment! 🐰"
            messages[assistantIndex].isStreaming = false
        }
        
        isLoading = false
    }
}

