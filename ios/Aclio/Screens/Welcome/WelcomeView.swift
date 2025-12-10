import SwiftUI

// MARK: - Welcome View
struct WelcomeView: View {
    let onGetStarted: () -> Void
    let onSignIn: () -> Void
    
    @State private var mascotScale: CGFloat = 0.8
    @State private var mascotOpacity: Double = 0
    @State private var titleOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    
    var body: some View {
        ZStack {
            // Background gradient
            AclioGradients.heroBackground
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                // Content
                VStack(spacing: AclioSpacing.space6) {
                    // Mascot with glow
                    ZStack {
                        // Glow
                        Circle()
                            .fill(AclioGradients.mascotGlow)
                            .frame(width: 280, height: 280)
                            .blur(radius: 40)
                        
                        // Mascot
                        Image("mascot")
                            .resizable()
                            .scaledToFit()
                            .frame(width: AdaptiveLayout.welcomeMascotSize, height: AdaptiveLayout.welcomeMascotSize)
                    }
                    .scaleEffect(mascotScale)
                    .opacity(mascotOpacity)
                    
                    // Title
                    VStack(spacing: AclioSpacing.space2) {
                        Text("Aclio")
                            .font(AclioFont.welcomeTitle)
                            .foregroundColor(.white)
                        
                        Text("Ignite your goals.")
                            .font(AclioFont.welcomeTagline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .opacity(titleOpacity)
                }
                
                Spacer()
                
                // Bottom buttons
                VStack(spacing: AclioSpacing.space4) {
                    Button(action: {
                        AclioHaptics.medium()
                        onGetStarted()
                    }) {
                        Text("Get Started")
                            .font(AclioFont.buttonLarge)
                            .foregroundColor(.aclioHeaderBg)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.white)
                            .cornerRadius(AclioRadius.button)
                    }
                    
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .font(AclioFont.body)
                            .foregroundColor(.white.opacity(0.6))
                        
                        Button(action: {
                            AclioHaptics.light()
                            onSignIn()
                        }) {
                            Text("Sign in")
                                .font(AclioFont.bodyMedium)
                                .foregroundColor(.white)
                                .underline()
                        }
                    }
                }
                .padding(.horizontal, AclioSpacing.screenHorizontal)
                .padding(.bottom, ScreenSize.safeBottom + AclioSpacing.space8)
                .opacity(buttonsOpacity)
            }
        }
        .onAppear {
            animateIn()
        }
    }
    
    private func animateIn() {
        // Mascot animation
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
            mascotScale = 1.0
            mascotOpacity = 1.0
        }
        
        // Title animation
        withAnimation(.easeOut(duration: 0.5).delay(0.5)) {
            titleOpacity = 1.0
        }
        
        // Buttons animation
        withAnimation(.easeOut(duration: 0.5).delay(0.7)) {
            buttonsOpacity = 1.0
        }
    }
}

// MARK: - Preview
#Preview {
    WelcomeView(onGetStarted: {}, onSignIn: {})
}


