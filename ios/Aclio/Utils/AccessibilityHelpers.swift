import SwiftUI

// MARK: - Accessibility Extensions

extension View {
    /// Adds accessibility label, hint, and traits in one call
    func accessible(
        label: String,
        hint: String? = nil,
        traits: AccessibilityTraits = []
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityAddTraits(traits)
    }
    
    /// Makes a button accessible with action description
    func accessibleButton(
        label: String,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "Double tap to activate")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Makes a toggleable element accessible
    func accessibleToggle(
        label: String,
        isOn: Bool,
        hint: String? = nil
    ) -> some View {
        self
            .accessibilityLabel(label)
            .accessibilityValue(isOn ? "On" : "Off")
            .accessibilityHint(hint ?? "Double tap to toggle")
            .accessibilityAddTraits(.isButton)
    }
    
    /// Combines multiple elements for VoiceOver
    func accessibilityGroup() -> some View {
        self.accessibilityElement(children: .combine)
    }
    
    /// Hides from VoiceOver (for decorative elements)
    func accessibilityHidden() -> some View {
        self.accessibilityHidden(true)
    }
}

// MARK: - Accessibility Announcements

enum AccessibilityAnnouncement {
    /// Announce when a goal is completed
    static func goalCompleted(_ goalName: String) {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Congratulations! Goal \(goalName) completed"
        )
    }
    
    /// Announce when a step is completed
    static func stepCompleted(_ stepTitle: String) {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Step completed: \(stepTitle)"
        )
    }
    
    /// Announce when a step is uncompleted
    static func stepUncompleted(_ stepTitle: String) {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Step marked incomplete: \(stepTitle)"
        )
    }
    
    /// Announce progress update
    static func progressUpdate(_ progress: Int) {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Progress: \(progress) percent"
        )
    }
    
    /// Announce error
    static func error(_ message: String) {
        UIAccessibility.post(
            notification: .announcement,
            argument: "Error: \(message)"
        )
    }
    
    /// Announce loading state
    static func loading(_ isLoading: Bool) {
        if isLoading {
            UIAccessibility.post(
                notification: .announcement,
                argument: "Loading"
            )
        }
    }
    
    /// Generic announcement
    static func announce(_ message: String) {
        UIAccessibility.post(
            notification: .announcement,
            argument: message
        )
    }
}

// MARK: - Accessibility Modifiers

struct AccessibilityProgressModifier: ViewModifier {
    let progress: Int
    let goalName: String
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel("\(goalName), \(progress) percent complete")
            .accessibilityValue("\(progress) percent")
    }
}

extension View {
    func accessibilityProgress(_ progress: Int, goalName: String) -> some View {
        modifier(AccessibilityProgressModifier(progress: progress, goalName: goalName))
    }
}

// MARK: - Semantic Content Descriptions

struct GoalAccessibility {
    let goal: Goal
    
    var label: String {
        var description = goal.name
        if let category = goal.category {
            description += ", \(category)"
        }
        description += ", \(goal.progress) percent complete"
        return description
    }
    
    var hint: String {
        if goal.isCompleted {
            return "Goal completed. Double tap to view details."
        } else if let nextStep = goal.nextStep {
            return "Next step: \(nextStep.title). Double tap to continue."
        }
        return "Double tap to view goal details."
    }
    
    var dueDateDescription: String? {
        guard let status = goal.dueDateStatus else { return nil }
        switch status {
        case .overdue:
            return "Overdue"
        case .today:
            return "Due today"
        case .soon(let days):
            return "Due in \(days) days"
        case .normal(let days):
            return "\(days) days remaining"
        }
    }
}

struct StepAccessibility {
    let step: Step
    let isCompleted: Bool
    
    var label: String {
        var description = step.title
        if isCompleted {
            description += ", completed"
        } else {
            description += ", not completed"
        }
        return description
    }
    
    var hint: String {
        if isCompleted {
            return "Double tap to mark as incomplete"
        }
        return "Double tap to mark as complete"
    }
    
    var value: String {
        isCompleted ? "Completed" : "Not completed"
    }
}

