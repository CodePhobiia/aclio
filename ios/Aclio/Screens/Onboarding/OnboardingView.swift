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
            mascotImage: "mascot-checklist", // Mascot with checklist
            title: "Your goals, broken into simple steps",
            subtitle: "Aclio transforms big ambitions into daily, doable actions.",
            features: [
                OnboardingFeatureData(icon: "square.grid.2x2.fill", iconColor: Color(hex: "6366F1"), text: "Customized step-by-step plans"),
                OnboardingFeatureData(icon: "wand.and.stars", iconColor: Color(hex: "6366F1"), text: "\"Do it for me\" detailed tasks"),
                OnboardingFeatureData(icon: "rocket.fill", iconColor: Color(hex: "6366F1"), text: "Timeline-based progress")
            ],
            buttonText: "Next →",
            isChecklistSlide: true
        ),
        OnboardingSlideData(
            mascotImage: "mascot-trophy", // Mascot with trophy and confetti
            title: "Achieve more with smart motivation",
            subtitle: "Streaks, progress insights, and reminders keep you moving forward.",
            features: [
                OnboardingFeatureData(icon: "flame.fill", iconColor: Color(hex: "6366F1"), text: "Streak tracking & rewards"),
                OnboardingFeatureData(icon: "checkmark.seal.fill", iconColor: Color(hex: "6366F1"), text: "Personalized nudges"),
                OnboardingFeatureData(icon: "trophy.fill", iconColor: Color(hex: "6366F1"), text: "Achievement badges")
            ],
            buttonText: "Finish Setup",
            isTrophySlide: true
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
    var isChecklistSlide: Bool = false
    var isTrophySlide: Bool = false
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
                // Mascot image (images already include their decorations)
                Image(slide.mascotImage)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        width: slide.isChecklistSlide || slide.isTrophySlide ? 220 : 180,
                        height: slide.isChecklistSlide || slide.isTrophySlide ? 220 : 180
                    )
            }
            .frame(height: 240)
            
            Spacer()
                .frame(height: 24)
            
            // Title
            Text(slide.title)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(Color(hex: "0B1C36"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            
            Spacer()
                .frame(height: 12)
            
            // Subtitle
            Text(slide.subtitle)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(hex: "6B7280"))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
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

// MARK: - Preview
#Preview {
    OnboardingView(onComplete: {}, onSkip: {})
}
