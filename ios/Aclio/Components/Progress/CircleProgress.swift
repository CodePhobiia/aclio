import SwiftUI

// MARK: - Circle Progress
struct CircleProgress: View {
    let progress: Double
    let size: CGFloat
    let strokeWidth: CGFloat
    let showBackground: Bool
    let gradient: LinearGradient?
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        progress: Double,
        size: CGFloat = 56,
        strokeWidth: CGFloat = 6,
        showBackground: Bool = true,
        gradient: LinearGradient? = nil
    ) {
        self.progress = min(max(progress, 0), 1)
        self.size = size
        self.strokeWidth = strokeWidth
        self.showBackground = showBackground
        self.gradient = gradient
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        ZStack {
            // Background circle
            if showBackground {
                Circle()
                    .stroke(colors.progressBackground, lineWidth: strokeWidth)
            }
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    gradient ?? AclioGradients.progressFill,
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Circle Progress with Label
struct CircleProgressWithLabel: View {
    let progress: Double
    let size: CGFloat
    let strokeWidth: CGFloat
    let showPercentage: Bool
    let label: String?
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        progress: Double,
        size: CGFloat = 100,
        strokeWidth: CGFloat = 8,
        showPercentage: Bool = true,
        label: String? = nil
    ) {
        self.progress = min(max(progress, 0), 1)
        self.size = size
        self.strokeWidth = strokeWidth
        self.showPercentage = showPercentage
        self.label = label
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        ZStack {
            CircleProgress(progress: progress, size: size, strokeWidth: strokeWidth)
            
            VStack(spacing: 0) {
                if showPercentage {
                    Text("\(Int(progress * 100))%")
                        .font(size > 80 ? AclioFont.statMedium : AclioFont.statSmall)
                        .foregroundColor(colors.textPrimary)
                }
                
                if let label = label {
                    Text(label)
                        .font(AclioFont.caption)
                        .foregroundColor(colors.textMuted)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        HStack(spacing: 24) {
            CircleProgress(progress: 0.25, size: 40, strokeWidth: 4)
            CircleProgress(progress: 0.5, size: 56)
            CircleProgress(progress: 0.75, size: 80, strokeWidth: 8)
        }
        
        HStack(spacing: 24) {
            CircleProgressWithLabel(progress: 0.33, size: 80)
            CircleProgressWithLabel(progress: 0.67, size: 100, label: "Overall")
        }
    }
    .padding()
}


