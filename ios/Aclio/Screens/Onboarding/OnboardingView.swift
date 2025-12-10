import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    @State private var currentPage = 0
    
    private let slides = OnboardingSlide.slides
    
    var body: some View {
        ZStack {
            // Background
            Color.aclioPageBg
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
                            .font(AclioFont.bodyMedium)
                            .foregroundColor(.aclioTextSecondary)
                    }
                }
                .padding(.horizontal, AclioSpacing.screenHorizontal)
                .padding(.top, ScreenSize.safeTop + AclioSpacing.space3)
                
                // Content
                TabView(selection: $currentPage) {
                    ForEach(Array(slides.enumerated()), id: \.offset) { index, slide in
                        OnboardingSlideView(slide: slide)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.3), value: currentPage)
                
                // Bottom section
                VStack(spacing: AclioSpacing.space5) {
                    // Page indicators
                    HStack(spacing: AclioSpacing.space2) {
                        ForEach(0..<slides.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentPage ? Color.aclioOrange : Color.aclioOrange.opacity(0.3))
                                .frame(width: index == currentPage ? 10 : 8, height: index == currentPage ? 10 : 8)
                                .animation(.spring(response: 0.3), value: currentPage)
                        }
                    }
                    
                    // Next/Get Started button
                    PrimaryButton(
                        currentPage < slides.count - 1 ? "Next" : "Get Started",
                        icon: currentPage < slides.count - 1 ? "arrow.right" : nil
                    ) {
                        if currentPage < slides.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            onComplete()
                        }
                    }
                }
                .padding(.horizontal, AclioSpacing.screenHorizontal)
                .padding(.bottom, ScreenSize.safeBottom + AclioSpacing.space6)
            }
        }
    }
}

// MARK: - Onboarding Slide View
struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        VStack(spacing: AclioSpacing.space6) {
            Spacer()
            
            // Illustration
            ZStack {
                // Blob background
                Circle()
                    .fill(Color(hex: slide.iconBgHex).opacity(0.15))
                    .frame(width: AdaptiveLayout.onboardingImageSize * 1.5, height: AdaptiveLayout.onboardingImageSize * 1.5)
                
                // Image
                Image(systemName: slideSystemImage)
                    .font(.system(size: AdaptiveLayout.onboardingImageSize * 0.5, weight: .medium))
                    .foregroundColor(Color(hex: slide.iconColorHex))
                
                // Icon badge
                Image(systemName: slide.systemIcon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 48, height: 48)
                    .background(Color(hex: slide.iconColorHex))
                    .clipShape(Circle())
                    .offset(x: 50, y: -50)
            }
            
            // Text content
            VStack(spacing: AclioSpacing.space3) {
                Text(slide.title)
                    .font(AclioFont.onboardingTitle)
                    .foregroundColor(colors.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text(slide.text)
                    .font(AclioFont.onboardingText)
                    .foregroundColor(colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            .padding(.horizontal, AclioSpacing.space4)
            
            // Features / Tasks / Badge
            if let features = slide.features {
                VStack(spacing: AclioSpacing.space3) {
                    ForEach(features) { feature in
                        HStack(spacing: AclioSpacing.space3) {
                            Image(systemName: feature.systemIcon)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(hex: slide.iconColorHex))
                                .frame(width: 24)
                            
                            Text(feature.text)
                                .font(AclioFont.body)
                                .foregroundColor(colors.textPrimary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, AclioSpacing.space4)
                        .padding(.vertical, AclioSpacing.space3)
                        .background(colors.cardBackground)
                        .cornerRadius(AclioRadius.medium)
                    }
                }
                .padding(.horizontal, AclioSpacing.space2)
            }
            
            if let tasks = slide.tasks {
                VStack(spacing: AclioSpacing.space2) {
                    ForEach(Array(tasks.enumerated()), id: \.offset) { index, task in
                        HStack(spacing: AclioSpacing.space3) {
                            ZStack {
                                Circle()
                                    .stroke(index < 2 ? colors.success : colors.border, lineWidth: 2)
                                    .frame(width: 20, height: 20)
                                
                                if index < 2 {
                                    Circle()
                                        .fill(colors.success)
                                        .frame(width: 20, height: 20)
                                    
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            
                            Text(task)
                                .font(AclioFont.body)
                                .foregroundColor(index < 2 ? colors.textMuted : colors.textPrimary)
                                .strikethrough(index < 2)
                            
                            Spacer()
                        }
                        .padding(.horizontal, AclioSpacing.space4)
                        .padding(.vertical, AclioSpacing.space3)
                        .background(colors.cardBackground)
                        .cornerRadius(AclioRadius.medium)
                    }
                }
                .padding(.horizontal, AclioSpacing.space2)
            }
            
            if let badge = slide.badge {
                HStack(spacing: AclioSpacing.space2) {
                    Image(systemName: badge.systemIcon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.aclioGold)
                    
                    Text(badge.text)
                        .font(AclioFont.bodyMedium)
                        .foregroundColor(colors.textPrimary)
                }
                .padding(.horizontal, AclioSpacing.space5)
                .padding(.vertical, AclioSpacing.space3)
                .background(Color.aclioGold.opacity(0.15))
                .cornerRadius(AclioRadius.full)
            }
            
            Spacer()
        }
    }
    
    private var slideSystemImage: String {
        switch slide.imageUrl {
        case "lightbulb": return "lightbulb.fill"
        case "clipboard": return "list.bullet.clipboard.fill"
        case "trophy": return "trophy.fill"
        default: return "star.fill"
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(onComplete: {}, onSkip: {})
}


