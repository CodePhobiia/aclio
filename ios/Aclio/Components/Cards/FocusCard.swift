import SwiftUI

// MARK: - Focus Card (Today's Focus)
struct FocusCard: View {
    let tasks: [FocusTask]
    let onToggle: (FocusTask) -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            // Header
            HStack(spacing: AclioSpacing.space2) {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colors.accent)
                
                Text("Today's Focus")
                    .font(AclioFont.cardTitle)
                    .foregroundColor(colors.textPrimary)
            }
            
            // Tasks
            ForEach(tasks) { task in
                FocusTaskRow(task: task, onToggle: { onToggle(task) })
            }
        }
        .padding(AclioSpacing.cardPadding)
        .background(colors.cardBackground)
        .cornerRadius(AclioRadius.card)
        .aclioCardShadow(isDark: colorScheme == .dark)
    }
}

// MARK: - Focus Task Model
struct FocusTask: Identifiable {
    let id: String
    let stepId: Int
    let goalId: Int
    let title: String
    let goalName: String
    var isCompleted: Bool
    
    init(step: Step, goal: Goal) {
        self.id = "\(goal.id)-\(step.id)"
        self.stepId = step.id
        self.goalId = goal.id
        self.title = step.title
        self.goalName = goal.name
        self.isCompleted = goal.completedSteps.contains(step.id)
    }
}

// MARK: - Focus Task Row
struct FocusTaskRow: View {
    let task: FocusTask
    let onToggle: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        Button(action: {
            AclioHaptics.medium()
            onToggle()
        }) {
            HStack(spacing: AclioSpacing.space3) {
                // Checkbox
                ZStack {
                    Circle()
                        .stroke(task.isCompleted ? colors.success : colors.border, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if task.isCompleted {
                        Circle()
                            .fill(colors.success)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                
                // Content
                VStack(alignment: .leading, spacing: 2) {
                    Text(task.title)
                        .font(AclioFont.body)
                        .foregroundColor(task.isCompleted ? colors.textMuted : colors.textPrimary)
                        .strikethrough(task.isCompleted)
                        .lineLimit(2)
                    
                    Text(task.goalName)
                        .font(AclioFont.caption)
                        .foregroundColor(colors.textMuted)
                }
                
                Spacer()
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    let tasks = [
        FocusTask(step: Step(id: 1, title: "Complete Swift Basics"), goal: Goal.sample),
        FocusTask(step: Step(id: 2, title: "Run for 30 minutes"), goal: Goal.sampleCompleted),
    ]
    
    FocusCard(tasks: tasks, onToggle: { _ in })
        .padding()
        .background(Color.aclioPageBg)
}


