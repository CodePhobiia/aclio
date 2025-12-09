import SwiftUI

// MARK: - Goal Detail View
struct GoalDetailView: View {
    @StateObject private var viewModel: GoalDetailViewModel
    
    let onBack: () -> Void
    let onNavigateToChat: (Goal) -> Void
    let onDeleted: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var showDeleteConfirm = false
    
    init(goal: Goal, onBack: @escaping () -> Void, onNavigateToChat: @escaping (Goal) -> Void, onDeleted: @escaping () -> Void) {
        _viewModel = StateObject(wrappedValue: GoalDetailViewModel(goal: goal))
        self.onBack = onBack
        self.onNavigateToChat = onNavigateToChat
        self.onDeleted = onDeleted
    }
    
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
                headerView
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AclioSpacing.sectionGap) {
                        // Goal Card
                        goalInfoCard
                        
                        // Talk to Aclio
                        talkToAclioCard
                        
                        // Steps Section
                        stepsSection
                        
                        // Error Message
                        if let error = viewModel.error {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(AclioFont.caption)
                                    .foregroundColor(colors.textSecondary)
                            }
                            .padding()
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(AclioRadius.medium)
                        }
                        
                        // Delete Button
                        deleteButton
                    }
                    .padding(.horizontal, AclioSpacing.screenHorizontal)
                    .padding(.bottom, ScreenSize.safeBottom + AclioSpacing.space8)
                }
            }
            
            // Celebration Modal
            if viewModel.showCelebration {
                celebrationModal
            }
            
            // AI Loading Overlays
            if viewModel.expandingStepId != nil {
                AILoadingOverlay.expandingStep
            }
            
            if viewModel.doingItForMeStepId != nil {
                AILoadingOverlay.doingItForMe
            }
        }
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView(onDismiss: { viewModel.dismissPaywall() })
        }
        .sheet(isPresented: $viewModel.showExpandedResult) {
            if let step = viewModel.expandedResultStep {
                ExpandedContentView(
                    stepTitle: step.title,
                    detailedGuide: viewModel.expandedResultGuide,
                    tips: viewModel.expandedResultTips,
                    resources: viewModel.expandedResultResources,
                    isAlreadySaved: viewModel.expandedResultIsSaved,
                    onExit: { viewModel.dismissExpandedResult() },
                    onSave: { viewModel.saveExpandedContent() }
                )
            }
        }
        .sheet(isPresented: $viewModel.showDoItForMeResult) {
            if let step = viewModel.doItForMeResultStep {
                DoItForMeResultView(
                    stepTitle: step.title,
                    result: viewModel.doItForMeResultContent,
                    onDismiss: { viewModel.dismissDoItForMeResult() },
                    onMarkComplete: { viewModel.markDoItForMeStepComplete() }
                )
            }
        }
        .confirmationDialog("Delete Goal", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                viewModel.deleteGoal()
                onDeleted()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this goal?")
        }
    }
    
    // MARK: - Header
    private var headerView: some View {
        HStack {
            BackButton(action: onBack)
            
            Spacer()
            
            Text("Goal Details")
                .font(AclioFont.navTitle)
                .foregroundColor(colors.textPrimary)
            
            Spacer()
            
            IconButton(icon: "trash", style: .ghost) {
                showDeleteConfirm = true
            }
        }
        .padding(.horizontal, AclioSpacing.screenHorizontal)
        .padding(.top, ScreenSize.safeTop + AclioSpacing.space3)
        .padding(.bottom, AclioSpacing.space3)
    }
    
    // MARK: - Goal Info Card
    private var goalInfoCard: some View {
        VStack(spacing: AclioSpacing.space4) {
            // Header row
            HStack(spacing: AclioSpacing.space3) {
                // Icon
                ZStack {
                    Circle()
                        .fill(viewModel.goal.iconColor.bgColor)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: GoalIcons.systemName(for: viewModel.goal.iconKey))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(viewModel.goal.iconColor.fgColor)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.goal.name)
                        .font(AclioFont.title3)
                        .foregroundColor(colors.textPrimary)
                    
                    if let category = viewModel.goal.category {
                        Text(category)
                            .font(AclioFont.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    if let dueDate = viewModel.goal.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                            Text("Due: \(dueDate.formatted())")
                                .font(AclioFont.caption)
                        }
                        .foregroundColor(colors.textMuted)
                    }
                }
                
                Spacer()
            }
            
            // Progress
            HStack(spacing: AclioSpacing.space4) {
                ZStack {
                    CircleProgressWithLabel(
                        progress: Double(viewModel.progress) / 100,
                        size: 56,
                        strokeWidth: 6,
                        showPercentage: false
                    )
                    
                    Text("\(viewModel.progress)%")
                        .font(AclioFont.captionMedium)
                        .foregroundColor(colors.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("PROGRESS")
                        .font(AclioFont.captionMedium)
                        .foregroundColor(colors.textMuted)
                    
                    Text("\(viewModel.goal.completedStepsCount) of \(viewModel.goal.totalStepsCount) steps completed")
                        .font(AclioFont.body)
                        .foregroundColor(colors.textPrimary)
                }
                
                Spacer()
            }
            .padding(AclioSpacing.space4)
            .background(colors.pillBackground)
            .cornerRadius(AclioRadius.medium)
        }
        .padding(AclioSpacing.cardPadding)
        .background(colors.cardBackground)
        .cornerRadius(AclioRadius.card)
        .aclioCardShadow(isDark: colorScheme == .dark)
    }
    
    // MARK: - Talk to Aclio Card
    private var talkToAclioCard: some View {
        Button(action: {
            onNavigateToChat(viewModel.goal)
        }) {
            HStack(spacing: AclioSpacing.space3) {
                MascotView(size: .small, faceOnly: true)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Talk to Aclio")
                        .font(AclioFont.cardTitle)
                        .foregroundColor(colors.textPrimary)
                    
                    Text("Get personalized advice and motivation for this goal")
                        .font(AclioFont.caption)
                        .foregroundColor(colors.textSecondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(colors.textMuted)
            }
            .padding(AclioSpacing.cardPadding)
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.card)
            .aclioCardShadow(isDark: colorScheme == .dark)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Steps Section
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            Text("Action Steps")
                .font(AclioFont.sectionTitle)
                .foregroundColor(colors.textPrimary)
            
            LazyVStack(spacing: AclioSpacing.cardGap) {
                ForEach(Array(viewModel.goal.steps.enumerated()), id: \.element.id) { index, step in
                    StepItemView(
                        step: step,
                        stepNumber: step.id,
                        isCompleted: viewModel.goal.isStepCompleted(step.id),
                        isExpanding: viewModel.expandingStepId == step.id,
                        isDoingIt: viewModel.doingItForMeStepId == step.id,
                        hasSavedExpand: viewModel.isStepExpanded(step.id),
                        onToggle: {
                            viewModel.toggleStep(step.id)
                        },
                        onExpand: {
                            Task {
                                await viewModel.expandStep(step)
                            }
                        },
                        onViewExpand: {
                            viewModel.viewSavedExpand(step)
                        },
                        onDoItForMe: {
                            Task {
                                await viewModel.doItForMe(step)
                            }
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - Delete Button
    private var deleteButton: some View {
        SecondaryButton("Delete Goal", icon: "trash", style: .destructive) {
            showDeleteConfirm = true
        }
    }
    
    // MARK: - Celebration Modal
    private var celebrationModal: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.dismissCelebration()
                }
            
            VStack(spacing: AclioSpacing.space6) {
                Text("🎉")
                    .font(.system(size: 64))
                
                Text("Goal Achieved!")
                    .font(AclioFont.title1)
                    .foregroundColor(colors.textPrimary)
                
                Text("Congratulations! You've completed all steps for \"\(viewModel.goal.name)\". You're amazing!")
                    .font(AclioFont.body)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
                
                HStack(spacing: AclioSpacing.space3) {
                    SecondaryButton("Back to Dashboard") {
                        viewModel.dismissCelebration()
                        onBack()
                    }
                    
                    PrimaryButton("View Goal") {
                        viewModel.dismissCelebration()
                    }
                }
            }
            .padding(AclioSpacing.space8)
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.xxl)
            .padding(.horizontal, AclioSpacing.space6)
        }
    }
}

// MARK: - Preview
#Preview {
    GoalDetailView(
        goal: Goal.sample,
        onBack: {},
        onNavigateToChat: { _ in },
        onDeleted: {}
    )
}

