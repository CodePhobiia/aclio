import SwiftUI

// MARK: - Welcome View (Screen 1)
struct WelcomeView: View {
    let onGetStarted: () -> Void
    let onSkip: () -> Void
    
    @State private var hasAppeared: Bool = false
    @State private var mascotScale: CGFloat = 0.5
    @State private var mascotOpacity: Double = 0
    @State private var contentOpacity: Double = 0
    @State private var buttonsOpacity: Double = 0
    
    // Light blue/gray background color
    private let backgroundColor = Color(hex: "E8EDF5")
    
    var body: some View {
        ZStack {
            // Light background
            backgroundColor
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    Button(action: {
                        AclioHaptics.light()
                        onSkip()
                    }) {
                        Text("Skip")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "FF9F3A"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, ScreenSize.safeTop + 16)
                
                Spacer()
                
                // Main content
                VStack(spacing: 24) {
                    // Mascot with glow - Fixed frame to prevent layout jumps
                    ZStack {
                        // Soft glow beneath mascot
                        Ellipse()
                            .fill(
                                RadialGradient(
                                    colors: [Color(hex: "FF9F3A").opacity(0.15), Color.clear],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 100
                                )
                            )
                            .frame(width: 200, height: 60)
                            .offset(y: 80)
                            .opacity(mascotOpacity)
                        
                        // Mascot image
                        Image("mascot")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 180, height: 180)
                            .scaleEffect(mascotScale)
                            .opacity(mascotOpacity)
                    }
                    .frame(width: 200, height: 200) // Fixed frame prevents layout shift
                    
                    // Title
                    HStack(spacing: 8) {
                        Text("Welcome to Aclio")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(hex: "0B1C36"))
                        
                        Text("🔥")
                            .font(.system(size: 26))
                    }
                    
                    // Subtitle
                    Text("The AI that helps you achieve your goals\n— step by step.")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(Color(hex: "6B7280"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .opacity(contentOpacity)
                
                Spacer()
                    .frame(height: 32)
                
                // Feature cards
                VStack(spacing: 12) {
                    OnboardingFeatureCard(
                        icon: "sparkles",
                        iconColor: Color(hex: "FF9F3A"),
                        text: "Turn any goal into a guided plan"
                    )
                    
                    OnboardingFeatureCard(
                        icon: "bolt.fill",
                        iconColor: Color(hex: "FF9F3A"),
                        text: "Smart suggestions tailored to you"
                    )
                    
                    OnboardingFeatureCard(
                        icon: "magnifyingglass",
                        iconColor: Color(hex: "FF9F3A"),
                        text: "Understand your habits & motivation"
                    )
                }
                .padding(.horizontal, 24)
                .opacity(contentOpacity)
                
                Spacer()
                
                // Bottom buttons
                VStack(spacing: 16) {
                    // Get Started button with gradient
                    Button(action: {
                        AclioHaptics.medium()
                        onGetStarted()
                    }) {
                        Text("Get Started")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                LinearGradient(
                                    colors: [Color(hex: "FFA63E"), Color(hex: "FF8A3D"), Color(hex: "FFB85C")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(28)
                            .shadow(color: Color(hex: "FF9F3A").opacity(0.3), radius: 12, x: 0, y: 6)
                    }
                    
                    // Skip to App link
                    Button(action: {
                        AclioHaptics.light()
                        onSkip()
                    }) {
                        Text("Skip to App")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(Color(hex: "9CA3AF"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, ScreenSize.safeBottom + 24)
                .opacity(buttonsOpacity)
            }
        }
        .onAppear {
            // Delay animation slightly to ensure layout is complete
            guard !hasAppeared else { return }
            hasAppeared = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                animateIn()
            }
        }
    }
    
    private func animateIn() {
        // Mascot appears with bounce
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            mascotOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1)) {
            mascotScale = 1.0
        }
        
        // Content fades in
        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
            contentOpacity = 1.0
        }
        
        // Buttons fade in last
        withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
            buttonsOpacity = 1.0
        }
    }
}

// MARK: - Onboarding Feature Card
struct OnboardingFeatureCard: View {
    let icon: String
    let iconColor: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(iconColor)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "1F2937"))
            
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Preview
#Preview {
    WelcomeView(onGetStarted: {}, onSkip: {})
}

