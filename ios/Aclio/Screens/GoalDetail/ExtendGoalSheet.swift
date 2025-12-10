import SwiftUI

// MARK: - Extend Goal Sheet
struct ExtendGoalSheet: View {
    let goalName: String
    let onExtend: (String) -> Void
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var extensionText: String = ""
    @FocusState private var isTextFocused: Bool
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    private let suggestions = [
        "Add advanced techniques",
        "Include maintenance habits",
        "Add accountability measures",
        "Include celebration milestones"
    ]
    
    var body: some View {
        NavigationView {
            ZStack {
                colors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AclioSpacing.space5) {
                        // Header
                        headerSection
                        
                        // Goal context
                        goalContextCard
                        
                        // Input section
                        inputSection
                        
                        // Suggestions
                        suggestionsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AclioSpacing.screenHorizontal)
                    .padding(.top, AclioSpacing.space4)
                }
                .scrollDismissesKeyboard(.immediately)
                
                // Bottom CTA
                VStack {
                    Spacer()
                    bottomCTA
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(colors.textSecondary)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Extend Goal")
                        .font(AclioFont.navTitle)
                        .foregroundColor(colors.textPrimary)
                }
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: AclioSpacing.space3) {
            ZStack {
                Circle()
                    .fill(AclioGradients.mascotGlow)
                    .frame(width: 80, height: 80)
                    .blur(radius: 15)
                
                ZStack {
                    Circle()
                        .fill(colors.accentSoft)
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "arrow.triangle.branch")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(colors.accent)
                }
            }
            
            Text("Keep the momentum going!")
                .font(AclioFont.title3)
                .foregroundColor(colors.textPrimary)
            
            Text("Tell Aclio what you'd like to add for future steps")
                .font(AclioFont.body)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Goal Context Card
    private var goalContextCard: some View {
        HStack(spacing: AclioSpacing.space3) {
            Image(systemName: "target")
                .font(.system(size: 18))
                .foregroundColor(colors.accent)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Current Goal")
                    .font(AclioFont.caption)
                    .foregroundColor(colors.textMuted)
                
                Text(goalName)
                    .font(AclioFont.cardTitle)
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(AclioSpacing.cardPadding)
        .background(colors.pillBackground)
        .cornerRadius(AclioRadius.card)
    }
    
    // MARK: - Input Section
    private var inputSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space2) {
            Text("What would you like to add?")
                .font(AclioFont.inputLabel)
                .foregroundColor(colors.textSecondary)
            
            ZStack(alignment: .topLeading) {
                TextEditor(text: $extensionText)
                    .font(AclioFont.input)
                    .foregroundColor(colors.textPrimary)
                    .frame(minHeight: 100, maxHeight: 150)
                    .padding(AclioSpacing.space3)
                    .focused($isTextFocused)
                    .scrollContentBackground(.hidden)
                
                if extensionText.isEmpty {
                    Text("e.g., Add steps for maintaining my progress long-term...")
                        .font(AclioFont.input)
                        .foregroundColor(colors.textMuted)
                        .padding(.horizontal, AclioSpacing.space3 + 5)
                        .padding(.top, AclioSpacing.space3 + 8)
                        .allowsHitTesting(false)
                }
            }
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.card)
            .overlay(
                RoundedRectangle(cornerRadius: AclioRadius.card)
                    .stroke(isTextFocused ? colors.accent : colors.border, lineWidth: 1)
            )
        }
    }
    
    // MARK: - Suggestions Section
    private var suggestionsSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space2) {
            Text("Quick suggestions")
                .font(AclioFont.caption)
                .foregroundColor(colors.textMuted)
            
            FlowLayout(spacing: AclioSpacing.space2) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: {
                        AclioHaptics.light()
                        extensionText = suggestion
                    }) {
                        Text(suggestion)
                            .font(AclioFont.caption)
                            .foregroundColor(colors.textSecondary)
                            .padding(.horizontal, AclioSpacing.space3)
                            .padding(.vertical, AclioSpacing.space2)
                            .background(colors.pillBackground)
                            .cornerRadius(AclioRadius.full)
                    }
                }
            }
        }
    }
    
    // MARK: - Bottom CTA
    private var bottomCTA: some View {
        VStack(spacing: 0) {
            Divider()
            
            VStack(spacing: AclioSpacing.space3) {
                PrimaryButton(
                    "Generate New Steps",
                    icon: "sparkles",
                    isDisabled: extensionText.trimmingCharacters(in: .whitespaces).isEmpty
                ) {
                    AclioHaptics.medium()
                    onExtend(extensionText)
                }
                
                Text("AI will create additional steps based on your request")
                    .font(AclioFont.caption)
                    .foregroundColor(colors.textMuted)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, AclioSpacing.screenHorizontal)
            .padding(.vertical, AclioSpacing.space4)
            .padding(.bottom, ScreenSize.safeBottom)
        }
        .background(colors.cardBackground)
    }
}

// MARK: - Preview
#Preview {
    ExtendGoalSheet(
        goalName: "Learn to play guitar",
        onExtend: { _ in },
        onDismiss: {}
    )
}

