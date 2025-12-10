import SwiftUI

// MARK: - Goal Card
struct GoalCard: View {
    let goal: Goal
    let onTap: () -> Void
    let onDelete: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var offset: CGFloat = 0
    @State private var showDelete = false
    
    init(goal: Goal, onTap: @escaping () -> Void, onDelete: (() -> Void)? = nil) {
        self.goal = goal
        self.onTap = onTap
        self.onDelete = onDelete
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background
            if onDelete != nil {
                HStack {
                    Spacer()
                    Button(action: {
                        AclioHaptics.medium()
                        onDelete?()
                    }) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 60)
                            .frame(maxHeight: .infinity)
                    }
                }
                .background(colors.destructive)
                .cornerRadius(AclioRadius.card)
            }
            
            // Main card
            VStack(alignment: .leading, spacing: AclioSpacing.cardGap) {
                // Header
                HStack(spacing: AclioSpacing.space3) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(goal.iconColor.bgColor)
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: GoalIcons.systemName(for: goal.iconKey))
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(goal.iconColor.fgColor)
                    }
                    
                    // Info
                    VStack(alignment: .leading, spacing: 2) {
                        Text(goal.name)
                            .font(AclioFont.cardTitle)
                            .foregroundColor(colors.textPrimary)
                            .lineLimit(2)
                        
                        Text(goal.category ?? "Personal Goal")
                            .font(AclioFont.caption)
                            .foregroundColor(colors.textSecondary)
                        
                        // Due date badge
                        if let status = goal.dueDateStatus {
                            HStack(spacing: 4) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 10))
                                Text(status.text)
                                    .font(AclioFont.captionMedium)
                            }
                            .foregroundColor(status.isUrgent ? colors.destructive : colors.textMuted)
                            .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                }
                
                // Progress row
                HStack {
                    Text("Progress")
                        .font(AclioFont.caption)
                        .foregroundColor(colors.textMuted)
                    
                    Spacer()
                    
                    Text("\(goal.progress)%")
                        .font(AclioFont.captionMedium)
                        .foregroundColor(colors.accent)
                }
                
                // Progress bar
                ProgressBar(progress: Double(goal.progress) / 100)
                
                // Next step
                if let nextStep = goal.nextStep {
                    HStack(spacing: AclioSpacing.space2) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(colors.accent)
                        
                        Text(nextStep.title)
                            .font(AclioFont.caption)
                            .foregroundColor(colors.textSecondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, AclioSpacing.space3)
                    .padding(.vertical, AclioSpacing.space2)
                    .background(colors.accentSoft)
                    .cornerRadius(AclioRadius.small)
                }
            }
            .padding(AclioSpacing.cardPadding)
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.card)
            .aclioCardShadow(isDark: colorScheme == .dark)
            .offset(x: offset)
            .simultaneousGesture(
                onDelete != nil ?
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        // Only respond to horizontal drags (allow vertical scrolling)
                        let horizontalAmount = abs(value.translation.width)
                        let verticalAmount = abs(value.translation.height)
                        
                        // If dragging more vertically, don't interfere with scroll
                        if verticalAmount > horizontalAmount {
                            return
                        }
                        
                        // Only allow left swipe
                        if value.translation.width < 0 {
                            offset = max(value.translation.width, -80)
                        }
                    }
                    .onEnded { value in
                        // Only act if it was a horizontal swipe
                        let horizontalAmount = abs(value.translation.width)
                        let verticalAmount = abs(value.translation.height)
                        
                        if horizontalAmount > verticalAmount && value.translation.width < -50 {
                            withAnimation(.spring()) {
                                offset = -80
                                showDelete = true
                            }
                        } else {
                            withAnimation(.spring()) {
                                offset = 0
                                showDelete = false
                            }
                        }
                    }
                : nil
            )
            .onTapGesture {
                if offset == 0 {
                    AclioHaptics.light()
                    onTap()
                } else {
                    withAnimation(.spring()) {
                        offset = 0
                        showDelete = false
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        GoalCard(goal: Goal.sample, onTap: {}, onDelete: {})
        GoalCard(goal: Goal.sampleCompleted, onTap: {})
    }
    .padding()
    .background(Color.aclioPageBg)
}

