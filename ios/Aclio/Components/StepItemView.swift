import SwiftUI

// MARK: - Step Item View
struct StepItemView: View {
    let step: Step
    let stepNumber: Int
    let isCompleted: Bool
    let isExpanding: Bool
    let isDoingIt: Bool
    let expandedContent: String?
    let onToggle: () -> Void
    let onExpand: () -> Void
    let onDoItForMe: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            HStack(alignment: .top, spacing: AclioSpacing.space3) {
                // Checkbox
                Button(action: {
                    AclioHaptics.medium()
                    onToggle()
                }) {
                    ZStack {
                        Circle()
                            .stroke(isCompleted ? colors.success : colors.border, lineWidth: 2)
                            .frame(width: 24, height: 24)
                        
                        if isCompleted {
                            Circle()
                                .fill(colors.success)
                                .frame(width: 24, height: 24)
                            
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: AclioSpacing.space2) {
                    // Title
                    HStack(spacing: 0) {
                        Text("Step \(stepNumber): ")
                            .font(AclioFont.stepPrefix)
                            .foregroundColor(colors.textMuted)
                        
                        Text(step.title)
                            .font(AclioFont.stepTitle)
                            .foregroundColor(isCompleted ? colors.textMuted : colors.textPrimary)
                            .strikethrough(isCompleted)
                    }
                    
                    // Description
                    if !step.description.isEmpty {
                        Text(step.description)
                            .font(AclioFont.stepDescription)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    // Duration
                    if let duration = step.duration {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                            Text(duration)
                                .font(AclioFont.stepDuration)
                        }
                        .foregroundColor(colors.textMuted)
                    }
                    
                    // Expanded content
                    if let content = expandedContent {
                        Text(content)
                            .font(AclioFont.body)
                            .foregroundColor(colors.textSecondary)
                            .padding(AclioSpacing.space3)
                            .background(colors.pillBackground)
                            .cornerRadius(AclioRadius.small)
                            .padding(.top, AclioSpacing.space2)
                    }
                    
                    // Action buttons (only if not completed)
                    if !isCompleted {
                        HStack(spacing: AclioSpacing.space2) {
                            StepActionButton(
                                title: "Expand",
                                icon: "arrow.up.left.and.arrow.down.right",
                                isLoading: isExpanding,
                                isDone: expandedContent != nil,
                                action: onExpand
                            )
                            
                            StepActionButton(
                                title: "Do it for me",
                                icon: "wand.and.stars",
                                isLoading: isDoingIt,
                                style: .accent,
                                action: onDoItForMe
                            )
                        }
                        .padding(.top, AclioSpacing.space2)
                    }
                }
                
                Spacer()
                
                // Completed indicator
                if isCompleted {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(colors.success)
                }
            }
        }
        .padding(AclioSpacing.cardPadding)
        .background(colors.cardBackground)
        .cornerRadius(AclioRadius.card)
        .opacity(isCompleted ? 0.7 : 1)
    }
}

// MARK: - Step Action Button
struct StepActionButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let isDone: Bool
    let style: ButtonStyle
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    enum ButtonStyle {
        case normal
        case accent
    }
    
    init(
        title: String,
        icon: String,
        isLoading: Bool = false,
        isDone: Bool = false,
        style: ButtonStyle = .normal,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDone = isDone
        self.style = style
        self.action = action
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        Button(action: {
            AclioHaptics.light()
            action()
        }) {
            HStack(spacing: 4) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(0.7)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .medium))
                }
                
                Text(title)
                    .font(AclioFont.captionMedium)
            }
            .foregroundColor(style == .accent ? colors.accent : colors.teal)
            .padding(.horizontal, AclioSpacing.space3)
            .padding(.vertical, AclioSpacing.space2)
            .background(style == .accent ? colors.accentSoft : colors.tealSoft)
            .cornerRadius(AclioRadius.small)
            .opacity(isDone ? 0.5 : 1)
        }
        .disabled(isLoading || isDone)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 12) {
        StepItemView(
            step: Step(id: 1, title: "Learn Swift basics", description: "Study variables, functions, and control flow", duration: "2 hours"),
            stepNumber: 1,
            isCompleted: false,
            isExpanding: false,
            isDoingIt: false,
            expandedContent: nil,
            onToggle: {},
            onExpand: {},
            onDoItForMe: {}
        )
        
        StepItemView(
            step: Step(id: 2, title: "Build first app", description: "Create a Hello World app"),
            stepNumber: 2,
            isCompleted: true,
            isExpanding: false,
            isDoingIt: false,
            expandedContent: nil,
            onToggle: {},
            onExpand: {},
            onDoItForMe: {}
        )
    }
    .padding()
    .background(Color.aclioPageBg)
}

