import SwiftUI

// MARK: - Mascot View
struct MascotView: View {
    let size: MascotSize
    let showGlow: Bool
    let faceOnly: Bool
    
    enum MascotSize {
        case small
        case medium
        case large
        case extraLarge
        
        var dimension: CGFloat {
            switch self {
            case .small: return AclioSpacing.mascotSmall
            case .medium: return AclioSpacing.mascotMedium
            case .large: return AclioSpacing.mascotLarge
            case .extraLarge: return AclioSpacing.mascotXL
            }
        }
        
        var glowRadius: CGFloat {
            switch self {
            case .small: return 30
            case .medium: return 50
            case .large: return 80
            case .extraLarge: return 120
            }
        }
    }
    
    init(size: MascotSize = .medium, showGlow: Bool = false, faceOnly: Bool = false) {
        self.size = size
        self.showGlow = showGlow
        self.faceOnly = faceOnly
    }
    
    var body: some View {
        ZStack {
            // Glow effect
            if showGlow {
                Circle()
                    .fill(AclioGradients.mascotGlow)
                    .frame(width: size.dimension * 1.5, height: size.dimension * 1.5)
                    .blur(radius: size.glowRadius / 3)
            }
            
            // Mascot image
            Image(faceOnly ? "mascot-face" : "mascot")
                .resizable()
                .scaledToFit()
                .frame(width: size.dimension, height: size.dimension)
        }
    }
}

// MARK: - Animated Mascot
struct AnimatedMascot: View {
    let size: MascotView.MascotSize
    
    @State private var isAnimating = false
    
    var body: some View {
        MascotView(size: size, showGlow: true)
            .scaleEffect(isAnimating ? 1.05 : 1.0)
            .animation(
                .easeInOut(duration: 1.5)
                .repeatForever(autoreverses: true),
                value: isAnimating
            )
            .onAppear {
                isAnimating = true
            }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        HStack(spacing: 24) {
            MascotView(size: .small, faceOnly: true)
            MascotView(size: .medium, faceOnly: true)
            MascotView(size: .large, faceOnly: true)
        }
        
        MascotView(size: .extraLarge, showGlow: true)
        
        AnimatedMascot(size: .large)
    }
    .padding()
    .background(Color.aclioHeaderBg)
}


