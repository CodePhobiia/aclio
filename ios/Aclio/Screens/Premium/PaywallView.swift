import SwiftUI

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
                        planButtons
                        
                        // Trial Toggle
                        trialToggle
                        
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
                        Text("No commitments. Cancel anytime.")
                            .font(AclioFont.caption)
                            .foregroundColor(colors.textMuted)
                        
                        // Restore
                        Button(action: {
                            Task {
                                let _ = await viewModel.restore()
                            }
                        }) {
                            Text("Restore Purchases")
                                .font(AclioFont.captionMedium)
                                .foregroundColor(colors.textSecondary)
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
            Text("\(viewModel.selectedPlan.period) Plan")
                .font(AclioFont.captionMedium)
                .foregroundColor(.white.opacity(0.8))
            
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(viewModel.selectedPlan.price)
                    .font(AclioFont.paywallPrice)
                    .foregroundColor(.white)
                
                Text("/ \(viewModel.selectedPlan.periodLabel)")
                    .font(AclioFont.paywallPeriod)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AclioSpacing.space6)
        .background(AclioGradients.paywallCard)
        .cornerRadius(AclioRadius.large)
    }
    
    // MARK: - Plan Buttons
    private var planButtons: some View {
        HStack(spacing: AclioSpacing.space3) {
            ForEach(viewModel.plans) { plan in
                Button(action: {
                    AclioHaptics.selection()
                    viewModel.selectPlan(plan)
                }) {
                    VStack(spacing: 4) {
                        Text(plan.period)
                            .font(AclioFont.buttonSmall)
                            .foregroundColor(viewModel.selectedPlan.id == plan.id ? .white : colors.textPrimary)
                        
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
                    .background(
                        viewModel.selectedPlan.id == plan.id
                        ? colors.accent
                        : colors.pillBackground
                    )
                    .cornerRadius(AclioRadius.button)
                    .overlay(
                        RoundedRectangle(cornerRadius: AclioRadius.button)
                            .stroke(
                                viewModel.selectedPlan.id == plan.id
                                ? colors.accent
                                : colors.border,
                                lineWidth: 1
                            )
                    )
                }
            }
        }
    }
    
    // MARK: - Trial Toggle
    private var trialToggle: some View {
        HStack {
            Text("3-day free trial")
                .font(AclioFont.body)
                .foregroundColor(colors.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $viewModel.trialEnabled)
                .labelsHidden()
                .tint(colors.accent)
        }
        .padding(AclioSpacing.space4)
        .background(colors.cardBackground)
        .cornerRadius(AclioRadius.medium)
    }
}

// MARK: - Preview
#Preview {
    PaywallView(onDismiss: {})
}


