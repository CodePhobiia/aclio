import SwiftUI

// MARK: - Chat View
struct ChatView: View {
    @StateObject private var viewModel: ChatViewModel
    @StateObject private var keyboardObserver = KeyboardObserver()
    
    let onBack: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isInputFocused: Bool
    
    init(goal: Goal?, onBack: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: ChatViewModel(goal: goal))
        self.onBack = onBack
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header
                    chatHeader
                    
                    // Messages
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: AclioSpacing.space3) {
                                ForEach(viewModel.messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                                
                                // Typing indicator
                                if viewModel.isLoading && (viewModel.messages.last?.content.isEmpty ?? true) {
                                    typingIndicator
                                }
                            }
                            .padding(.horizontal, AclioSpacing.screenHorizontal)
                            .padding(.vertical, AclioSpacing.space4)
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .onChange(of: viewModel.messages.count) { _ in
                            if let lastId = viewModel.messages.last?.id {
                                withAnimation {
                                    proxy.scrollTo(lastId, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: keyboardObserver.isKeyboardVisible) { isVisible in
                            if isVisible, let lastId = viewModel.messages.last?.id {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation {
                                        proxy.scrollTo(lastId, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Quick prompts
                    if viewModel.messages.count <= 1 && !keyboardObserver.isKeyboardVisible {
                        quickPrompts
                    }
                    
                    // Input area
                    inputArea
                }
            }
            .ignoresSafeArea(.keyboard)
            .padding(.bottom, keyboardObserver.keyboardHeight > 0 ? keyboardObserver.keyboardHeight - geometry.safeAreaInsets.bottom : 0)
            .animation(.easeOut(duration: 0.25), value: keyboardObserver.keyboardHeight)
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView(onDismiss: { viewModel.dismissPaywall() })
        }
        .errorAlert($viewModel.error) {
            Task {
                await viewModel.retryLastMessage()
            }
        }
    }
    
    // MARK: - Chat Header
    private var chatHeader: some View {
        HStack(spacing: AclioSpacing.space3) {
            BackButton(action: onBack)
            
            HStack(spacing: AclioSpacing.space3) {
                MascotView(size: .small, faceOnly: true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Aclio")
                        .font(AclioFont.chatName)
                        .foregroundColor(colors.textPrimary)
                    
                    Text("Your AI Goal Coach")
                        .font(AclioFont.chatStatus)
                        .foregroundColor(colors.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, AclioSpacing.screenHorizontal)
        .padding(.top, ScreenSize.safeTop + AclioSpacing.space3)
        .padding(.bottom, AclioSpacing.space3)
        .background(colors.cardBackground)
    }
    
    // MARK: - Typing Indicator
    private var typingIndicator: some View {
        HStack(spacing: AclioSpacing.space2) {
            MascotView(size: .small, faceOnly: true)
                .frame(width: 32, height: 32)
            
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(colors.textMuted)
                        .frame(width: 8, height: 8)
                        .opacity(typingDotOpacity(index))
                }
            }
            .padding(.horizontal, AclioSpacing.space4)
            .padding(.vertical, AclioSpacing.space3)
            .background(colors.pillBackground)
            .cornerRadius(AclioRadius.large)
            
            Spacer()
        }
    }
    
    @State private var typingAnimation = false
    
    private func typingDotOpacity(_ index: Int) -> Double {
        let delay = Double(index) * 0.2
        return typingAnimation ? 1.0 : 0.3
    }
    
    // MARK: - Quick Prompts
    private var quickPrompts: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AclioSpacing.space2) {
                ForEach(viewModel.quickPrompts, id: \.self) { prompt in
                    QuickPromptChip(text: prompt) {
                        viewModel.selectQuickPrompt(prompt)
                    }
                }
            }
            .padding(.horizontal, AclioSpacing.screenHorizontal)
        }
        .padding(.vertical, AclioSpacing.space3)
    }
    
    // MARK: - Input Area
    private var inputArea: some View {
        HStack(spacing: AclioSpacing.space3) {
            TextField("Ask Aclio anything...", text: $viewModel.inputText, axis: .vertical)
                .font(AclioFont.body)
                .foregroundColor(colors.textPrimary)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .padding(.horizontal, AclioSpacing.space4)
                .padding(.vertical, AclioSpacing.space3)
                .background(colors.inputBackground)
                .cornerRadius(AclioRadius.full)
                .onSubmit {
                    Task {
                        await viewModel.sendMessage()
                    }
                }
            
            Button(action: {
                Task {
                    await viewModel.sendMessage()
                }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(viewModel.canSend ? colors.accent : colors.textMuted)
            }
            .disabled(!viewModel.canSend)
        }
        .padding(.horizontal, AclioSpacing.screenHorizontal)
        .padding(.vertical, AclioSpacing.space3)
        .padding(.bottom, keyboardObserver.isKeyboardVisible ? AclioSpacing.space2 : ScreenSize.safeBottom)
        .background(colors.cardBackground)
    }
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: ChatMessage
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    private var isUser: Bool {
        message.role == .user
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: AclioSpacing.space2) {
            if !isUser {
                MascotView(size: .small, faceOnly: true)
                    .frame(width: 32, height: 32)
            } else {
                Spacer()
            }
            
            Group {
                if message.content.isEmpty && message.isStreaming {
                    Text("...")
                        .font(AclioFont.chatMessage)
                        .foregroundColor(isUser ? .white : colors.textPrimary)
                } else if isUser {
                    Text(message.content)
                        .font(AclioFont.chatMessage)
                        .foregroundColor(.white)
                } else {
                    LinkableText(text: message.content, textColor: colors.textPrimary)
                }
            }
            .padding(.horizontal, AclioSpacing.space4)
            .padding(.vertical, AclioSpacing.space3)
            .background(isUser ? colors.accent : colors.pillBackground)
            .cornerRadius(AclioRadius.large)
            
            if isUser {
                // No avatar for user
            } else {
                Spacer()
            }
        }
    }
}

// MARK: - Linkable Text
struct LinkableText: View {
    let text: String
    let textColor: Color
    
    var body: some View {
        Text(attributedString)
            .font(AclioFont.chatMessage)
            .tint(Color(hex: "3B82F6")) // Blue link color
    }
    
    private var attributedString: AttributedString {
        var attributedString = AttributedString(text)
        
        // Find URLs in the text
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let nsString = text as NSString
        let range = NSRange(location: 0, length: nsString.length)
        
        guard let matches = detector?.matches(in: text, options: [], range: range) else {
            // Apply default text color if no links found
            attributedString.foregroundColor = textColor
            return attributedString
        }
        
        // Apply default text color first
        attributedString.foregroundColor = textColor
        
        // Then apply link styling to URLs
        for match in matches {
            guard let matchRange = Range(match.range, in: text),
                  let url = match.url else { continue }
            
            if let attributedRange = Range(matchRange, in: attributedString) {
                attributedString[attributedRange].link = url
                attributedString[attributedRange].foregroundColor = Color(hex: "3B82F6")
                attributedString[attributedRange].underlineStyle = .single
            }
        }
        
        return attributedString
    }
}

// MARK: - Preview
#Preview {
    ChatView(goal: Goal.sample, onBack: {})
}

