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
                        
                        // CTA
                        PrimaryButton(
                            "Continue",
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
                            Text("No commitments. Cancel anytime.")
                                .font(AclioFont.caption)
                                .foregroundColor(colors.textMuted)
                            
                            Text("Auto-renews. Cancel in Settings.")
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
                    VStack(spacing: 4) {
                        Text(package.periodName)
                            .font(AclioFont.buttonSmall)
                            .foregroundColor(isSelected ? .white : colors.textPrimary)
                        
                        Text(package.localizedPriceString)
                            .font(AclioFont.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : colors.textSecondary)
                        
                        if package.isBestValue {
                            Text("Best")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.aclioSuccess)
                                .cornerRadius(4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AclioSpacing.space3)
                    .background(isSelected ? colors.accent : colors.pillBackground)
                    .cornerRadius(AclioRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: AclioRadius.button)
                            .stroke(isSelected ? colors.accent : colors.border, lineWidth: 1)
                    )
                }
            }
        }
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
                    VStack(spacing: 4) {
                        Text(plan.period)
                            .font(AclioFont.buttonSmall)
                            .foregroundColor(isSelected ? .white : colors.textPrimary)
                        
                        Text(plan.price)
                            .font(AclioFont.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : colors.textSecondary)
                        
                        if plan.isBestValue {
                            Text("Best")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.aclioSuccess)
                                .cornerRadius(4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, AclioSpacing.space3)
                    .background(isSelected ? colors.accent : colors.pillBackground)
                    .cornerRadius(AclioRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: AclioRadius.button)
                            .stroke(isSelected ? colors.accent : colors.border, lineWidth: 1)
                    )
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    PaywallView(onDismiss: {})
}
