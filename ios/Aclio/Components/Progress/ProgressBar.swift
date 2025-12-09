import SwiftUI

// MARK: - Progress Bar
struct ProgressBar: View {
    let progress: Double
    let height: CGFloat
    let gradient: LinearGradient?
    let animated: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @State private var animatedProgress: Double = 0
    
    init(
        progress: Double,
        height: CGFloat = 6,
        gradient: LinearGradient? = nil,
        animated: Bool = true
    ) {
        self.progress = min(max(progress, 0), 1)
        self.height = height
        self.gradient = gradient
        self.animated = animated
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                Capsule()
                    .fill(colors.progressBackground)
                    .frame(height: height)
                
                // Fill
                Capsule()
                    .fill(gradient ?? AclioGradients.progressFill)
                    .frame(width: geometry.size.width * (animated ? animatedProgress : progress), height: height)
            }
        }
        .frame(height: height)
        .onAppear {
            if animated {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                    animatedProgress = progress
                }
            }
        }
        .onChange(of: progress) { newValue in
            if animated {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    animatedProgress = newValue
                }
            }
        }
    }
}

// MARK: - Progress Bar with Label
struct ProgressBarWithLabel: View {
    let progress: Double
    let label: String?
    let showPercentage: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(progress: Double, label: String? = nil, showPercentage: Bool = true) {
        self.progress = progress
        self.label = label
        self.showPercentage = showPercentage
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        VStack(spacing: AclioSpacing.space2) {
            if label != nil || showPercentage {
                HStack {
                    if let label = label {
                        Text(label)
                            .font(AclioFont.caption)
                            .foregroundColor(colors.textMuted)
                    }
                    
                    Spacer()
                    
                    if showPercentage {
                        Text("\(Int(progress * 100))%")
                            .font(AclioFont.captionMedium)
                            .foregroundColor(colors.accent)
                    }
                }
            }
            
            ProgressBar(progress: progress)
        }
    }
}

// MARK: - Step Progress Indicator
struct StepProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        HStack(spacing: AclioSpacing.space2) {
            ForEach(0..<totalSteps, id: \.self) { index in
                if index < currentStep {
                    // Completed
                    Circle()
                        .fill(colors.success)
                        .frame(width: 8, height: 8)
                } else if index == currentStep {
                    // Current
                    Circle()
                        .fill(colors.accent)
                        .frame(width: 10, height: 10)
                } else {
                    // Upcoming
                    Circle()
                        .fill(colors.progressBackground)
                        .frame(width: 8, height: 8)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        ProgressBar(progress: 0.3)
        ProgressBar(progress: 0.6, gradient: AclioGradients.progressFillTeal)
        ProgressBar(progress: 0.9, gradient: AclioGradients.progressFillSuccess)
        
        ProgressBarWithLabel(progress: 0.45, label: "Progress")
        
        StepProgressIndicator(currentStep: 2, totalSteps: 5)
    }
    .padding()
}

