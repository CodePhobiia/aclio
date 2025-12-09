import SwiftUI

// MARK: - Expanded Content View
struct ExpandedContentView: View {
    let stepTitle: String
    let content: String
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    BackButton(action: onDismiss)
                    
                    Spacer()
                    
                    Text("Step Details")
                        .font(AclioFont.navTitle)
                        .foregroundColor(colors.textPrimary)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, AclioSpacing.screenHorizontal)
                .padding(.top, ScreenSize.safeTop + AclioSpacing.space3)
                .padding(.bottom, AclioSpacing.space3)
                .background(colors.headerBackground)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AclioSpacing.space6) {
                        // Step title card
                        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
                            HStack(spacing: AclioSpacing.space3) {
                                ZStack {
                                    Circle()
                                        .fill(colors.accentSoft)
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(colors.accent)
                                }
                                
                                Text(stepTitle)
                                    .font(AclioFont.title3)
                                    .foregroundColor(colors.textPrimary)
                            }
                        }
                        .padding(AclioSpacing.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colors.cardBackground)
                        .cornerRadius(AclioRadius.card)
                        .aclioCardShadow(isDark: colorScheme == .dark)
                        
                        // Content
                        VStack(alignment: .leading, spacing: AclioSpacing.space4) {
                            Text("Detailed Guide")
                                .font(AclioFont.sectionTitle)
                                .foregroundColor(colors.textPrimary)
                            
                            Text(content)
                                .font(AclioFont.body)
                                .foregroundColor(colors.textSecondary)
                                .lineSpacing(6)
                        }
                        .padding(AclioSpacing.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colors.cardBackground)
                        .cornerRadius(AclioRadius.card)
                        .aclioCardShadow(isDark: colorScheme == .dark)
                    }
                    .padding(.horizontal, AclioSpacing.screenHorizontal)
                    .padding(.vertical, AclioSpacing.space6)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Do It For Me Result View
struct DoItForMeResultView: View {
    let stepTitle: String
    let result: String
    let onDismiss: () -> Void
    let onMarkComplete: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var isCompleted = false
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    BackButton(action: onDismiss)
                    
                    Spacer()
                    
                    Text("Task Complete")
                        .font(AclioFont.navTitle)
                        .foregroundColor(colors.textPrimary)
                    
                    Spacer()
                    
                    // Invisible button for balance
                    Color.clear
                        .frame(width: 40, height: 40)
                }
                .padding(.horizontal, AclioSpacing.screenHorizontal)
                .padding(.top, ScreenSize.safeTop + AclioSpacing.space3)
                .padding(.bottom, AclioSpacing.space3)
                .background(colors.headerBackground)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AclioSpacing.space6) {
                        // Success header
                        HStack(spacing: AclioSpacing.space4) {
                            ZStack {
                                Circle()
                                    .fill(colors.successSoft)
                                    .frame(width: 56, height: 56)
                                
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(colors.success)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Done by Aclio!")
                                    .font(AclioFont.title3)
                                    .foregroundColor(colors.textPrimary)
                                
                                Text(stepTitle)
                                    .font(AclioFont.body)
                                    .foregroundColor(colors.textSecondary)
                                    .lineLimit(2)
                            }
                        }
                        .padding(AclioSpacing.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            LinearGradient(
                                colors: [colors.successSoft, colors.cardBackground],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(AclioRadius.card)
                        .aclioCardShadow(isDark: colorScheme == .dark)
                        
                        // Result content
                        VStack(alignment: .leading, spacing: AclioSpacing.space4) {
                            Text("Here's what I did:")
                                .font(AclioFont.sectionTitle)
                                .foregroundColor(colors.textPrimary)
                            
                            Text(result)
                                .font(AclioFont.body)
                                .foregroundColor(colors.textSecondary)
                                .lineSpacing(6)
                        }
                        .padding(AclioSpacing.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colors.cardBackground)
                        .cornerRadius(AclioRadius.card)
                        .aclioCardShadow(isDark: colorScheme == .dark)
                        
                        // Mark complete button
                        if !isCompleted {
                            PrimaryButton("Mark Step as Complete", icon: "checkmark") {
                                AclioHaptics.success()
                                isCompleted = true
                                onMarkComplete()
                            }
                        } else {
                            HStack(spacing: AclioSpacing.space3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(colors.success)
                                Text("Step marked as complete!")
                                    .font(AclioFont.bodyMedium)
                                    .foregroundColor(colors.success)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                    }
                    .padding(.horizontal, AclioSpacing.screenHorizontal)
                    .padding(.vertical, AclioSpacing.space6)
                }
            }
        }
        .navigationBarHidden(true)
    }
}

// MARK: - Previews
#Preview("Expanded Content") {
    ExpandedContentView(
        stepTitle: "Research industry trends",
        content: """
        **Understanding the Landscape**
        
        Start by identifying the top 5 companies in your target industry. Look at their recent news, product launches, and strategic moves.
        
        **Tips:**
        • Set up Google Alerts for industry keywords
        • Follow industry leaders on LinkedIn
        • Subscribe to relevant newsletters
        
        **Resources:**
        • Industry reports from McKinsey (Free summaries)
        • TechCrunch for tech industry news
        • LinkedIn Learning courses
        """,
        onDismiss: {}
    )
}

#Preview("Do It For Me Result") {
    DoItForMeResultView(
        stepTitle: "Create a weekly workout schedule",
        result: """
        Here's your personalized weekly workout schedule:
        
        **Monday - Upper Body**
        • Push-ups: 3 sets x 12 reps
        • Dumbbell rows: 3 sets x 10 reps
        • Shoulder press: 3 sets x 10 reps
        
        **Wednesday - Lower Body**
        • Squats: 3 sets x 15 reps
        • Lunges: 3 sets x 10 each leg
        • Calf raises: 3 sets x 20 reps
        
        **Friday - Full Body + Cardio**
        • Burpees: 3 sets x 8 reps
        • Mountain climbers: 3 sets x 30 seconds
        • 20-minute jog or bike ride
        
        Rest on Tuesday, Thursday, Saturday, and Sunday.
        """,
        onDismiss: {},
        onMarkComplete: {}
    )
}

