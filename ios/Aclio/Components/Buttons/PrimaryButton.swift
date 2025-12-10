import SwiftUI

// MARK: - Primary Button
struct PrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let showMascot: Bool
    let action: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        showMascot: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.showMascot = showMascot
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            AclioHaptics.medium()
            action()
        }) {
            HStack(spacing: AclioSpacing.space2) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.9)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    if showMascot {
                        Image("mascot-face")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    
                    Text(title)
                        .font(AclioFont.buttonLarge)
                }
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if isDisabled {
                        Color.gray.opacity(0.4)
                    } else {
                        AclioGradients.primaryOrange
                    }
                }
            )
            .cornerRadius(AclioRadius.button)
            .aclioShadow(isDisabled ? AclioShadow.xs : AclioShadow.buttonOrange)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1)
        .animation(.easeInOut(duration: 0.2), value: isLoading)
        .animation(.easeInOut(duration: 0.2), value: isDisabled)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        PrimaryButton("Get Started", icon: "sparkles") {}
        
        PrimaryButton("Generate Plan", showMascot: true) {}
        
        PrimaryButton("Loading...", isLoading: true) {}
        
        PrimaryButton("Disabled", isDisabled: true) {}
    }
    .padding()
}


