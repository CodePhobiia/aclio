import SwiftUI

// MARK: - AI Loading Overlay
/// A beautiful loading overlay for AI-powered features
struct AILoadingOverlay: View {
    let title: String
    let message: String
    let tips: [String]
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentTipIndex: Int = 0
    @State private var dotCount: Int = 0
    @State private var showTip: Bool = false
    @State private var mascotScale: CGFloat = 1.0
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    init(
        title: String = "Aclio is thinking",
        message: String = "This may take a moment...",
        tips: [String] = []
    ) {
        self.title = title
        self.message = message
        self.tips = tips
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            colors.background
                .opacity(0.95)
                .ignoresSafeArea()
            
            VStack(spacing: AclioSpacing.space6) {
                Spacer()
                
                // Mascot with pulse animation
                ZStack {
                    // Glow rings
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(colors.accent.opacity(0.15 - Double(index) * 0.04), lineWidth: 2)
                            .frame(width: 120 + CGFloat(index * 30), height: 120 + CGFloat(index * 30))
                            .scaleEffect(mascotScale)
                    }
                    
                    MascotView(size: .medium, showGlow: true, faceOnly: true)
                        .scaleEffect(mascotScale)
                }
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        mascotScale = 1.08
                    }
                }
                
                // Title with animated dots
                VStack(spacing: AclioSpacing.space2) {
                    HStack(spacing: 0) {
                        Text(title)
                            .font(AclioFont.title3)
                            .foregroundColor(colors.textPrimary)
                        
                        Text(String(repeating: ".", count: dotCount))
                            .font(AclioFont.title3)
                            .foregroundColor(colors.textPrimary)
                            .frame(width: 30, alignment: .leading)
                    }
                    
                    Text(message)
                        .font(AclioFont.body)
                        .foregroundColor(colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .onAppear {
                    startDotAnimation()
                }
                
                // Loading bar
                LoadingBar()
                    .frame(width: 200)
                
                // Rotating tips
                if !tips.isEmpty {
                    VStack(spacing: AclioSpacing.space2) {
                        HStack(spacing: AclioSpacing.space2) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.yellow)
                            
                            Text("Did you know?")
                                .font(AclioFont.captionMedium)
                                .foregroundColor(colors.textMuted)
                        }
                        
                        Text(tips[currentTipIndex])
                            .font(AclioFont.body)
                            .foregroundColor(colors.textSecondary)
                            .multilineTextAlignment(.center)
                            .opacity(showTip ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5), value: showTip)
                    }
                    .padding(.horizontal, AclioSpacing.space8)
                    .padding(.top, AclioSpacing.space4)
                    .onAppear {
                        showTip = true
                        startTipRotation()
                    }
                }
                
                Spacer()
                Spacer()
            }
            .padding(.horizontal, AclioSpacing.screenHorizontal)
        }
    }
    
    private func startDotAnimation() {
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
    
    private func startTipRotation() {
        guard tips.count > 1 else { return }
        Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            withAnimation(.easeOut(duration: 0.3)) {
                showTip = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                currentTipIndex = (currentTipIndex + 1) % tips.count
                withAnimation(.easeIn(duration: 0.3)) {
                    showTip = true
                }
            }
        }
    }
}

// MARK: - Loading Bar
struct LoadingBar: View {
    @State private var offset: CGFloat = -1.0
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(colors.pillBackground)
                    .frame(height: 6)
                
                // Animated gradient bar
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [colors.accent.opacity(0.3), colors.accent, colors.accent.opacity(0.3)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: geometry.size.width * 0.4, height: 6)
                    .offset(x: offset * geometry.size.width)
            }
        }
        .frame(height: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                offset = 0.6
            }
        }
    }
}

// MARK: - Preset Configurations
extension AILoadingOverlay {
    /// For generating goal steps
    static var generatingGoal: AILoadingOverlay {
        AILoadingOverlay(
            title: "Creating your plan",
            message: "Aclio is crafting personalized steps just for you",
            tips: [
                "Breaking down goals into small steps makes them 2x more achievable",
                "Specific deadlines increase your chance of success by 42%",
                "Celebrating small wins keeps motivation high"
            ]
        )
    }
    
    /// For expanding a step
    static var expandingStep: AILoadingOverlay {
        AILoadingOverlay(
            title: "Expanding step",
            message: "Getting detailed guidance and helpful resources",
            tips: [
                "Detailed plans reduce procrastination",
                "Learning the 'why' behind each step builds lasting habits",
                "Resources matched to your level accelerate progress"
            ]
        )
    }
    
    /// For "Do it for me"
    static var doingItForMe: AILoadingOverlay {
        AILoadingOverlay(
            title: "Working on it",
            message: "Aclio is completing this task for you",
            tips: [
                "Delegating tasks frees mental energy for what matters",
                "Even small progress adds up over time",
                "You're 10x more likely to achieve written goals"
            ]
        )
    }
    
    /// For generating personalized questions
    static var generatingQuestions: AILoadingOverlay {
        AILoadingOverlay(
            title: "Personalizing",
            message: "Creating questions tailored to your goal",
            tips: [
                "Personalized plans are 3x more effective",
                "Understanding your context helps Aclio guide you better"
            ]
        )
    }
}

// MARK: - Preview
#Preview("Generating Goal") {
    AILoadingOverlay.generatingGoal
}

#Preview("Expanding Step") {
    AILoadingOverlay.expandingStep
}

#Preview("Do It For Me") {
    AILoadingOverlay.doingItForMe
}

