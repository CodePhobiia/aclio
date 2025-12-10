import SwiftUI

// MARK: - Onboarding View (Screens 2 & 3)
struct OnboardingView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    @State private var currentPage = 0
    
    // Light blue/gray background color
    private let backgroundColor = Color(hex: "E8EDF5")
    
    private let slides: [OnboardingSlideData] = [
        OnboardingSlideData(
            mascotImage: "mascot", // Use checklist pose if available
            title: "Your goals, broken into simple steps",
            subtitle: "Aclio transforms big ambitions into daily, doable actions.",
            features: [
                OnboardingFeatureData(icon: "square.grid.2x2.fill", iconColor: Color(hex: "6366F1"), text: "Customized step-by-step plans"),
                OnboardingFeatureData(icon: "wand.and.stars", iconColor: Color(hex: "6366F1"), text: "\"Do it for me\" detailed tasks"),
                OnboardingFeatureData(icon: "rocket.fill", iconColor: Color(hex: "6366F1"), text: "Timeline-based progress")
            ],
            buttonText: "Next →"
        ),
        OnboardingSlideData(
            mascotImage: "mascot", // Use celebration pose if available
            title: "Achieve more with smart motivation",
            subtitle: "Streaks, progress insights, and reminders keep you moving forward.",
            features: [
                OnboardingFeatureData(icon: "flame.fill", iconColor: Color(hex: "6366F1"), text: "Streak tracking & rewards"),
                OnboardingFeatureData(icon: "checkmark.seal.fill", iconColor: Color(hex: "6366F1"), text: "Personalized nudges"),
                OnboardingFeatureData(icon: "trophy.fill", iconColor: Color(hex: "6366F1"), text: "Achievement badges")
            ],
            buttonText: "Finish Setup"
        )
    ]
    
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
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                        OnboardingSlideView2(slide: slide)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Bottom section
                VStack(spacing: 20) {
                    // Page indicators
                    HStack(spacing: 8) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color(hex: "FF9F3A") : Color(hex: "D1D5DB"))
                                .frame(width: 8, height: 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Next/Finish button with gradient
                    Button(action: {
                        AclioHaptics.medium()
                        if currentPage < slides.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            onComplete()
                        }
                    }) {
                        Text(slides[currentPage].buttonText)
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
                }
                .padding(.horizontal, 24)
                .padding(.bottom, ScreenSize.safeBottom + 24)
            }
        }
    }
}

// MARK: - Onboarding Slide Data
struct OnboardingSlideData {
    let mascotImage: String
    let title: String
    let subtitle: String
    let features: [OnboardingFeatureData]
    let buttonText: String
}

struct OnboardingFeatureData {
    let icon: String
    let iconColor: Color
    let text: String
}

// MARK: - Onboarding Slide View
struct OnboardingSlideView2: View {
    let slide: OnboardingSlideData
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Mascot area with illustration
            ZStack {
                // Checklist card behind mascot (for slide 1)
                if slide.title.contains("broken") {
                    // Checklist illustration
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(0..<3, id: \.self) { index in
                            HStack(spacing: 10) {
                                ZStack {
                                    Circle()
                                        .stroke(Color(hex: "3B82F6"), lineWidth: 2)
                                        .frame(width: 18, height: 18)
                                    
                                    if index < 2 {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Color(hex: "3B82F6"))
                                    }
                                }
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(hex: "E5E7EB"))
                                    .frame(width: 80, height: 8)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
                    .rotationEffect(.degrees(-8))
                    .offset(x: -60, y: -20)
                }
                
                // Mascot
                Image(slide.mascotImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .offset(x: slide.title.contains("broken") ? 30 : 0)
                
                // Confetti for celebration slide
                if slide.title.contains("motivation") {
                    ConfettiView()
                        .offset(y: -40)
                }
            }
            .frame(height: 200)
            
            Spacer()
                .frame(height: 24)
            
            // Title
            Text(slide.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Color(hex: "0B1C36"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)
            
            Spacer()
                .frame(height: 12)
            
            // Subtitle
            Text(slide.subtitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(hex: "6B7280"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 40)
            
            Spacer()
                .frame(height: 28)
            
            // Feature cards
            VStack(spacing: 12) {
                ForEach(Array(slide.features.enumerated()), id: \.offset) { _, feature in
                    OnboardingFeatureCard2(
                        icon: feature.icon,
                        iconColor: feature.iconColor,
                        text: feature.text
                    )
                }
            }
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
}

// MARK: - Onboarding Feature Card 2
struct OnboardingFeatureCard2: View {
    let icon: String
    let iconColor: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(hex: "1F2937"))
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Confetti View
struct ConfettiView: View {
    var body: some View {
        ZStack {
            ForEach(0..<20, id: \.self) { index in
                ConfettiPiece(
                    color: confettiColors[index % confettiColors.count],
                    offset: CGSize(
                        width: CGFloat.random(in: -80...80),
                        height: CGFloat.random(in: -60...40)
                    ),
                    rotation: Double.random(in: 0...360),
                    scale: CGFloat.random(in: 0.3...0.8)
                )
            }
        }
    }
    
    private let confettiColors: [Color] = [
        Color(hex: "FF6B6B"),
        Color(hex: "4ECDC4"),
        Color(hex: "FFE66D"),
        Color(hex: "95E1D3"),
        Color(hex: "F38181"),
        Color(hex: "AA96DA"),
        Color(hex: "6BCB77")
    ]
}

struct ConfettiPiece: View {
    let color: Color
    let offset: CGSize
    let rotation: Double
    let scale: CGFloat
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 8, height: 14)
            .rotationEffect(.degrees(rotation))
            .scaleEffect(scale)
            .offset(offset)
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(onComplete: {}, onSkip: {})
}
