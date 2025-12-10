import SwiftUI
import RevenueCat

// MARK: - Paywall View
struct PaywallView: View {
    @StateObject private var viewModel = PaywallViewModel()
    
    let onDismiss: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Close button
                HStack {
                    Spacer()
                    
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(colors.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(colors.pillBackground)
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, AclioSpacing.screenHorizontal)
                .padding(.top, AclioSpacing.space4)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AclioSpacing.space6) {
                        // Mascot
                        MascotView(size: .medium, showGlow: true, faceOnly: true)
                        
                        // Title
                        Text("Unlock Aclio Premium")
                            .font(AclioFont.paywallTitle)
                            .foregroundColor(colors.textPrimary)
                        
                        // Features
                        featuresSection
                        
                        // Price Card
                        priceCard
                        
                        // Plan Selection
                        if viewModel.useStaticPlans {
                            staticPlanButtons
                        } else if !viewModel.packages.isEmpty {
                            planButtons
                        } else if viewModel.isLoading {
                            ProgressView()
                                .frame(height: 60)
                        } else {
                            // Fallback if nothing loaded
                            staticPlanButtons
                        }
                        
                        // 3-Day Trial Banner
                        trialBanner
                        
                        // CTA
                        PrimaryButton(
                            "Start Free Trial",
                            isLoading: viewModel.isLoading
                        ) {
                            Task {
                                let success = await viewModel.purchase()
                                if success {
                                    onDismiss()
                                }
                            }
                        }
                        
                        // Terms
                        VStack(spacing: AclioSpacing.space2) {
                            Text("3-day free trial, then \(viewModel.selectedPrice)/\(viewModel.selectedPeriodLabel)")
                                .font(AclioFont.caption)
                                .foregroundColor(colors.textMuted)
                            
                            Text("No charge until trial ends. Cancel anytime.")
                                .font(AclioFont.caption)
                                .foregroundColor(colors.textMuted)
                        }
                        
                        // Restore
                        Button(action: {
                            Task {
                                let restored = await viewModel.restore()
                                if restored {
                                    onDismiss()
                                }
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(AclioFont.captionMedium)
                                .foregroundColor(colors.textSecondary)
                        }
                        
                        // Legal Links
                        HStack(spacing: AclioSpacing.space4) {
                            Link("Privacy Policy", destination: URL(string: "https://thecribbusiness.github.io/aclio/privacy")!)
                                .font(AclioFont.caption)
                                .foregroundColor(colors.textMuted)
                            
                            Text("•")
                                .foregroundColor(colors.textMuted)
                            
                            Link("Terms of Use", destination: URL(string: "https://thecribbusiness.github.io/aclio/terms")!)
                                .font(AclioFont.caption)
                                .foregroundColor(colors.textMuted)
                        }
                    }
                    .padding(.horizontal, AclioSpacing.screenHorizontal)
                    .padding(.bottom, ScreenSize.safeBottom + AclioSpacing.space8)
                }
            }
        }
    }
    
    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: AclioSpacing.space3) {
            ForEach(viewModel.features) { feature in
                HStack(alignment: .top, spacing: AclioSpacing.space3) {
                    ZStack {
                        Circle()
                            .fill(colors.successSoft)
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(colors.success)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(feature.title)
                            .font(AclioFont.paywallFeatureTitle)
                            .foregroundColor(colors.textPrimary)
                        
                        Text(feature.description)
                            .font(AclioFont.paywallFeatureDesc)
                            .foregroundColor(colors.textSecondary)
                    }
                    
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Price Card
    private var priceCard: some View {
        VStack(spacing: AclioSpacing.space2) {
            Text("\(viewModel.selectedPeriod) Plan")
                .font(AclioFont.captionMedium)
                .foregroundColor(.white.opacity(0.8))
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(viewModel.selectedPrice)
                    .font(AclioFont.paywallPrice)
                    .foregroundColor(.white)
                
                Text("/ \(viewModel.selectedPeriodLabel)")
                    .font(AclioFont.paywallPeriod)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Show savings for yearly
            if viewModel.useStaticPlans && viewModel.selectedStaticPlan.id == "yearly" {
                Text("Save 50% vs monthly")
                    .font(AclioFont.captionMedium)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 4)
            } else if viewModel.selectedPackage?.packageType == .annual {
                Text("Best Value - Save 50%")
                    .font(AclioFont.captionMedium)
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AclioSpacing.space6)
        .background(AclioGradients.paywallCard)
        .cornerRadius(AclioRadius.large)
    }
    
    // MARK: - Plan Buttons (RevenueCat)
    private var planButtons: some View {
        HStack(spacing: AclioSpacing.space3) {
            ForEach(viewModel.packages) { package in
                let isSelected = viewModel.selectedPackage?.id == package.id
                
                Button(action: {
                    AclioHaptics.selection()
                    viewModel.selectPackage(package)
                }) {
                    glassyPlanButtonContent(
                        title: package.periodName,
                        price: package.localizedPriceString,
                        isBestValue: package.isBestValue,
                        isSelected: isSelected
                    )
                }
            }
        }
    }
    
    // MARK: - Trial Banner
    private var trialBanner: some View {
        HStack(spacing: AclioSpacing.space3) {
            ZStack {
                Circle()
                    .fill(colors.successSoft)
                    .frame(width: 40, height: 40)
                
                Image(systemName: "gift.fill")
                    .font(.system(size: 18))
                    .foregroundColor(colors.success)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("3-Day Free Trial")
                    .font(AclioFont.cardTitle)
                    .foregroundColor(colors.textPrimary)
                
                Text("Try all premium features free for 3 days")
                    .font(AclioFont.caption)
                    .foregroundColor(colors.textSecondary)
            }
            
            Spacer()
        }
        .padding(AclioSpacing.space4)
        .background(colors.cardBackground)
        .cornerRadius(AclioRadius.card)
        .overlay(
            RoundedRectangle(cornerRadius: AclioRadius.card)
                .stroke(colors.success.opacity(0.3), lineWidth: 1)
        )
    }
    
    // MARK: - Static Plan Buttons (Fallback)
    private var staticPlanButtons: some View {
        HStack(spacing: AclioSpacing.space3) {
            ForEach(viewModel.staticPlans, id: \.id) { plan in
                let isSelected = viewModel.selectedStaticPlan.id == plan.id
                
                Button(action: {
                    AclioHaptics.selection()
                    viewModel.selectStaticPlan(plan)
                }) {
                    glassyPlanButtonContent(
                        title: plan.period,
                        price: plan.price,
                        isBestValue: plan.isBestValue,
                        isSelected: isSelected
                    )
                }
            }
        }
    }
    
    // MARK: - Glassy Plan Button Content
    @ViewBuilder
    private func glassyPlanButtonContent(
        title: String,
        price: String,
        isBestValue: Bool,
        isSelected: Bool
    ) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
            
            Text(price)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
            
            if isBestValue {
                Text("Best Value")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.25))
                    )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AclioSpacing.space4)
        .background(
            ZStack {
                // Base gradient
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isSelected 
                            ? AclioGradients.glassyPlanButtonSelected
                            : AclioGradients.glassyPlanButton
                    )
                
                // Glass refraction effect - top highlight
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isSelected ? 0.35 : 0.25),
                                Color.white.opacity(0.05),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
                
                // Inner glow for selected
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.6),
                                    Color.white.opacity(0.2),
                                    Color(hex: "A78BFA").opacity(0.3)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            }
        )
        .overlay(
            // Outer border
            RoundedRectangle(cornerRadius: 16)
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isSelected ? 0.5 : 0.3),
                            Color(hex: "8B7ED8").opacity(0.3),
                            Color.white.opacity(0.15)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(
            color: isSelected 
                ? Color(hex: "8B5CF6").opacity(0.4) 
                : Color(hex: "6B5DC7").opacity(0.2),
            radius: isSelected ? 12 : 6,
            x: 0,
            y: 4
        )
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Preview
#Preview {
    PaywallView(onDismiss: {})
}
