import SwiftUI

// MARK: - Step Item View
struct StepItemView: View {
    let step: Step
    let stepNumber: Int
    let isCompleted: Bool
    let isExpanding: Bool
    let isDoingIt: Bool
    let hasSavedExpand: Bool
    let onToggle: () -> Void
    let onExpand: () -> Void
    let onViewExpand: () -> Void
    let onDoItForMe: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    // MARK: - Accessibility
    
    private var stepAccessibilityLabel: String {
        var label = "Step \(stepNumber): \(step.title)"
        if isCompleted {
            label += ", completed"
        }
        if let duration = step.duration {
            label += ", estimated time \(duration)"
        }
        return label
    }
    
    private var checkboxAccessibilityLabel: String {
        isCompleted ? "Mark step \(stepNumber) as incomplete" : "Mark step \(stepNumber) as complete"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            HStack(alignment: .top, spacing: AclioSpacing.space3) {
                // Checkbox
                Button(action: {
                    AclioHaptics.medium()
                    onToggle()
                    // Accessibility announcement
                    let announcement = isCompleted ? "Step marked incomplete" : "Step completed"
                    UIAccessibility.post(notification: .announcement, argument: announcement)
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
                .accessibilityLabel(checkboxAccessibilityLabel)
                .accessibilityHint("Double tap to toggle completion")
                
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
                    
                    // Action buttons (only if not completed)
                    if !isCompleted {
                        HStack(spacing: AclioSpacing.space2) {
                            if hasSavedExpand {
                                // Show "View" button for saved expansions
                                StepActionButton(
                                    title: "View",
                                    icon: "eye",
                                    isLoading: false,
                                    style: .saved,
                                    action: onViewExpand
                                )
                            } else {
                                // Show "Expand" button for new expansions
                                StepActionButton(
                                    title: "Expand",
                                    icon: "arrow.up.left.and.arrow.down.right",
                                    isLoading: isExpanding,
                                    action: onExpand
                                )
                            }
                            
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
        // Overall accessibility for the step container
        .accessibilityElement(children: .contain)
        .accessibilityLabel(stepAccessibilityLabel)
    }
}

// MARK: - Step Action Button
struct StepActionButton: View {
    let title: String
    let icon: String
    let isLoading: Bool
    let style: ButtonStyle
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    enum ButtonStyle {
        case normal
        case accent
        case saved
    }
    
    init(
        title: String,
        icon: String,
        isLoading: Bool = false,
        style: ButtonStyle = .normal,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.style = style
        self.action = action
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    private var foregroundColor: Color {
        switch style {
        case .normal: return colors.teal
        case .accent: return colors.accent
        case .saved: return colors.success
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .normal: return colors.tealSoft
        case .accent: return colors.accentSoft
        case .saved: return colors.successSoft
        }
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
            .foregroundColor(foregroundColor)
            .padding(.horizontal, AclioSpacing.space3)
            .padding(.vertical, AclioSpacing.space2)
            .background(backgroundColor)
            .cornerRadius(AclioRadius.small)
        }
        .disabled(isLoading)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint(isLoading ? "Loading" : "Double tap to activate")
        .accessibilityAddTraits(.isButton)
    }
    
    private var accessibilityLabel: String {
        switch style {
        case .saved:
            return "View saved expansion for this step"
        case .accent:
            return "Have AI complete this step for you"
        case .normal:
            return "Expand step with more details"
        }
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
            hasSavedExpand: false,
            onToggle: {},
            onExpand: {},
            onViewExpand: {},
            onDoItForMe: {}
        )
        
        StepItemView(
            step: Step(id: 2, title: "Build first app", description: "Create a Hello World app"),
            stepNumber: 2,
            isCompleted: false,
            isExpanding: false,
            isDoingIt: false,
            hasSavedExpand: true,
            onToggle: {},
            onExpand: {},
            onViewExpand: {},
            onDoItForMe: {}
        )
        
        StepItemView(
            step: Step(id: 3, title: "Completed step", description: "This one is done"),
            stepNumber: 3,
            isCompleted: true,
            isExpanding: false,
            isDoingIt: false,
            hasSavedExpand: false,
            onToggle: {},
            onExpand: {},
            onViewExpand: {},
            onDoItForMe: {}
        )
    }
    .padding()
    .background(Color.aclioPageBg)
}

