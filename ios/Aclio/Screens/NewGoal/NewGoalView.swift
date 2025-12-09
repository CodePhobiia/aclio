import SwiftUI

// MARK: - New Goal View
struct NewGoalView: View {
    @StateObject private var viewModel = NewGoalViewModel()
    
    let onBack: () -> Void
    let onGoalCreated: (Goal) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isGoalInputFocused: Bool
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        ZStack {
            // Background
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HeaderView(title: "New Goal", onBack: {
                    viewModel.reset()
                    onBack()
                })
                
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AclioSpacing.space6) {
                            // Mascot header
                            mascotHeader
                            
                            // Question title
                            Text("What do you want to achieve?")
                                .font(AclioFont.title3)
                                .foregroundColor(colors.textPrimary)
                                .multilineTextAlignment(.center)
                            
                            // Goal input
                            goalInputCard
                            
                            // Quick suggestions
                            if viewModel.goalText.isEmpty {
                                quickSuggestions
                            }
                            
                            // Due date
                            dueDateSection
                            
                            // Icon selection
                            iconSelection
                            
                            // Color selection
                            colorSelection
                            
                            // AI Questions
                            if viewModel.showQuestions && !viewModel.questions.isEmpty {
                                questionsCard
                                    .id("questionsSection")
                            }
                            
                            // Error
                            if let error = viewModel.error {
                                errorMessage(error)
                            }
                        }
                        .padding(.horizontal, AclioSpacing.screenHorizontal)
                        .padding(.bottom, 160) // Space for CTA
                    }
                    .onChange(of: viewModel.questions.count) { _ in
                        // Auto-scroll to questions when they appear
                        if !viewModel.questions.isEmpty {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                proxy.scrollTo("questionsSection", anchor: .top)
                            }
                        }
                    }
                }
            }
            
            // CTA Footer
            ctaFooter
            
            // Generation Overlay
            if viewModel.isLoading {
                generationOverlay
            }
        }
        .onTapGesture {
            isGoalInputFocused = false
        }
    }
    
    // MARK: - Mascot Header
    private var mascotHeader: some View {
        ZStack {
            Circle()
                .fill(AclioGradients.mascotGlow)
                .frame(width: 100, height: 100)
                .blur(radius: 20)
            
            MascotView(size: .medium, faceOnly: true)
        }
        .padding(.top, AclioSpacing.space4)
    }
    
    // MARK: - Goal Input Card
    private var goalInputCard: some View {
        VStack(spacing: 0) {
            TextEditor(text: $viewModel.goalText)
                .font(AclioFont.input)
                .foregroundColor(colors.textPrimary)
                .frame(minHeight: 60, maxHeight: 100)
                .padding(AclioSpacing.space4)
                .focused($isGoalInputFocused)
                .scrollContentBackground(.hidden)
                .disabled(viewModel.isLoading)
        }
        .background(colors.cardBackground)
        .cornerRadius(AclioRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: AclioRadius.card)
                .stroke(isGoalInputFocused ? colors.accent : colors.border, lineWidth: 1)
        )
        .overlay(
            Group {
                if viewModel.goalText.isEmpty {
                    Text("e.g., Learn salsa, run a 5K...")
                        .font(AclioFont.input)
                        .foregroundColor(colors.textMuted)
                        .padding(.horizontal, AclioSpacing.space4 + 5)
                        .padding(.top, AclioSpacing.space4 + 8)
                        .allowsHitTesting(false)
                }
            },
            alignment: .topLeading
        )
    }
    
    // MARK: - Quick Suggestions
    private var quickSuggestions: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space2) {
            Text("Quick suggestions")
                .font(AclioFont.caption)
                .foregroundColor(colors.textMuted)
            
            FlowLayout(spacing: AclioSpacing.space2) {
                ForEach(viewModel.suggestions, id: \.self) { suggestion in
                    ChipView(suggestion) {
                        viewModel.selectSuggestion(suggestion)
                    }
                }
            }
        }
    }
    
    // MARK: - Due Date Section
    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space2) {
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 14))
                    .foregroundColor(colors.textMuted)
                
                Text("Target completion date (optional)")
                    .font(AclioFont.inputLabel)
                    .foregroundColor(colors.textSecondary)
            }
            
            DatePicker(
                "",
                selection: Binding(
                    get: { viewModel.dueDate ?? Date() },
                    set: { viewModel.dueDate = $0 }
                ),
                in: Date()...,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .padding(.horizontal, AclioSpacing.space4)
            .padding(.vertical, AclioSpacing.space3)
            .background(colors.inputBackground)
            .cornerRadius(AclioRadius.input)
        }
    }
    
    // MARK: - Icon Selection
    private var iconSelection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space2) {
            Text("Choose an icon")
                .font(AclioFont.inputLabel)
                .foregroundColor(colors.textSecondary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7), spacing: 8) {
                ForEach(Array(GoalIcons.keys.enumerated()), id: \.offset) { index, key in
                    let isSelected = viewModel.selectedIconIndex == index
                    
                    Button(action: {
                        AclioHaptics.selection()
                        viewModel.selectedIconIndex = index
                    }) {
                        Image(systemName: GoalIcons.systemName(for: key))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(isSelected ? IconColor.options[viewModel.selectedColorIndex].fgColor : colors.textMuted)
                            .frame(width: 44, height: 44)
                            .background(isSelected ? IconColor.options[viewModel.selectedColorIndex].bgColor : colors.cardBackground)
                            .cornerRadius(AclioRadius.medium)
                            .overlay(
                                RoundedRectangle(cornerRadius: AclioRadius.medium)
                                    .stroke(isSelected ? IconColor.options[viewModel.selectedColorIndex].fgColor : colors.border, lineWidth: isSelected ? 2 : 1)
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Color Selection
    private var colorSelection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space2) {
            Text("Choose a color")
                .font(AclioFont.inputLabel)
                .foregroundColor(colors.textSecondary)
            
            HStack(spacing: AclioSpacing.space3) {
                ForEach(Array(IconColor.options.enumerated()), id: \.element.id) { index, color in
                    let isSelected = viewModel.selectedColorIndex == index
                    
                    Button(action: {
                        AclioHaptics.selection()
                        viewModel.selectedColorIndex = index
                    }) {
                        Circle()
                            .fill(color.fgColor)
                            .frame(width: 36, height: 36)
                            .overlay(
                                Circle()
                                    .stroke(colors.textPrimary, lineWidth: isSelected ? 3 : 0)
                            )
                            .scaleEffect(isSelected ? 1.1 : 1.0)
                    }
                }
            }
        }
    }
    
    // MARK: - Questions Card
    private var questionsCard: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space4) {
            HStack(spacing: AclioSpacing.space3) {
                ZStack {
                    Circle()
                        .fill(colors.accentSoft)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(colors.accent)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tell us more")
                        .font(AclioFont.cardTitle)
                        .foregroundColor(colors.textPrimary)
                    
                    Text("Answer these to get a more personalized plan")
                        .font(AclioFont.caption)
                        .foregroundColor(colors.textSecondary)
                }
            }
            
            ForEach(Array(viewModel.questions.enumerated()), id: \.offset) { index, question in
                VStack(alignment: .leading, spacing: AclioSpacing.space2) {
                    HStack(spacing: AclioSpacing.space2) {
                        Text("\(index + 1)")
                            .font(AclioFont.captionMedium)
                            .foregroundColor(.white)
                            .frame(width: 20, height: 20)
                            .background(colors.accent)
                            .clipShape(Circle())
                        
                        Text(question.question)
                            .font(AclioFont.body)
                            .foregroundColor(colors.textPrimary)
                    }
                    
                    TextField(question.placeholder ?? "Your answer...", text: Binding(
                        get: { viewModel.answers[question.question] ?? "" },
                        set: { viewModel.updateAnswer(for: question.question, answer: $0) }
                    ))
                    .font(AclioFont.input)
                    .padding(AclioSpacing.space3)
                    .background(colors.inputBackground)
                    .cornerRadius(AclioRadius.input)
                }
            }
        }
        .padding(AclioSpacing.cardPadding)
        .background(colors.cardBackground)
        .cornerRadius(AclioRadius.card)
    }
    
    // MARK: - Error Message
    private func errorMessage(_ error: String) -> some View {
        HStack(spacing: AclioSpacing.space2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(colors.destructive)
            
            Text(error)
                .font(AclioFont.body)
                .foregroundColor(colors.destructive)
        }
        .padding(AclioSpacing.space4)
        .background(colors.destructiveSoft)
        .cornerRadius(AclioRadius.medium)
    }
    
    // MARK: - CTA Footer
    private var ctaFooter: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: AclioSpacing.space3) {
                // Loading Questions indicator
                if viewModel.isQuestionsLoading {
                    HStack(spacing: AclioSpacing.space3) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: colors.accent))
                        
                        Text("Loading personalized questions...")
                            .font(AclioFont.body)
                            .foregroundColor(colors.textSecondary)
                        
                        Spacer()
                    }
                    .padding(AclioSpacing.space4)
                    .background(colors.accentSoft)
                    .cornerRadius(AclioRadius.card)
                }
                // Personalize button
                else if !viewModel.showQuestions && viewModel.canSubmit && !viewModel.isLoading {
                    Button(action: {
                        Task {
                            await viewModel.generateQuestions()
                        }
                    }) {
                        HStack(spacing: AclioSpacing.space3) {
                            ZStack {
                                Circle()
                                    .fill(colors.accentSoft)
                                    .frame(width: 36, height: 36)
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16))
                                    .foregroundColor(colors.accent)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Personalize with questions")
                                    .font(AclioFont.cardTitle)
                                    .foregroundColor(colors.textPrimary)
                                
                                Text("Get a more tailored action plan")
                                    .font(AclioFont.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .foregroundColor(colors.textMuted)
                        }
                        .padding(AclioSpacing.space4)
                        .background(colors.cardBackground)
                        .cornerRadius(AclioRadius.card)
                    }
                }
                
                // Main CTA
                PrimaryButton(
                    viewModel.isLoading ? "Creating..." : "Generate Personalized Plan",
                    icon: viewModel.isLoading ? nil : "sparkles",
                    isLoading: viewModel.isLoading,
                    isDisabled: !viewModel.canSubmit || viewModel.isQuestionsLoading,
                    showMascot: !viewModel.isLoading
                ) {
                    Task {
                        if let goal = await viewModel.createGoal() {
                            onGoalCreated(goal)
                        }
                    }
                }
            }
            .padding(.horizontal, AclioSpacing.screenHorizontal)
            .padding(.bottom, ScreenSize.safeBottom + AclioSpacing.space4)
            .padding(.top, AclioSpacing.space4)
            .background(
                colors.background
                    .shadow(color: .black.opacity(0.1), radius: 10, y: -5)
            )
        }
    }
    
    // MARK: - Generation Overlay
    private var generationOverlay: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: AclioSpacing.space6) {
                // Animated icon
                ZStack {
                    Circle()
                        .fill(AclioGradients.mascotGlow)
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundColor(colors.accent)
                        .rotationEffect(.degrees(viewModel.isLoading ? 360 : 0))
                        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: viewModel.isLoading)
                }
                
                Text("Creating Your Plan")
                    .font(AclioFont.title2)
                    .foregroundColor(.white)
                
                Text(viewModel.currentGenerationMessage)
                    .font(AclioFont.body)
                    .foregroundColor(.white.opacity(0.7))
                
                // Progress
                VStack(spacing: AclioSpacing.space2) {
                    ProgressBar(progress: viewModel.progressPercent / 100)
                        .frame(width: 200)
                    
                    Text("\(Int(viewModel.progressPercent))% complete")
                        .font(AclioFont.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                // Steps
                VStack(spacing: AclioSpacing.space2) {
                    ForEach(GenerationStep.all) { step in
                        HStack(spacing: AclioSpacing.space3) {
                            ZStack {
                                Circle()
                                    .stroke(stepColor(for: step.id), lineWidth: 2)
                                    .frame(width: 24, height: 24)
                                
                                if viewModel.animatedStep > step.id {
                                    Circle()
                                        .fill(colors.success)
                                        .frame(width: 24, height: 24)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                } else if viewModel.animatedStep == step.id {
                                    Text("\(step.id)")
                                        .font(AclioFont.captionMedium)
                                        .foregroundColor(colors.accent)
                                } else {
                                    Text("\(step.id)")
                                        .font(AclioFont.captionMedium)
                                        .foregroundColor(.white.opacity(0.4))
                                }
                            }
                            
                            Text(step.text)
                                .font(AclioFont.body)
                                .foregroundColor(stepTextColor(for: step.id))
                            
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, AclioSpacing.space8)
            }
            .padding(AclioSpacing.space8)
        }
    }
    
    private func stepColor(for stepId: Int) -> Color {
        if viewModel.animatedStep > stepId {
            return colors.success
        } else if viewModel.animatedStep == stepId {
            return colors.accent
        }
        return .white.opacity(0.3)
    }
    
    private func stepTextColor(for stepId: Int) -> Color {
        if viewModel.animatedStep >= stepId {
            return .white
        }
        return .white.opacity(0.4)
    }
}

// MARK: - Preview
#Preview {
    NewGoalView(onBack: {}, onGoalCreated: { _ in })
}

