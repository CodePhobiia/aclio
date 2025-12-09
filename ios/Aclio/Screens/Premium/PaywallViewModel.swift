import Foundation
import Combine

// MARK: - Paywall View Model
@MainActor
final class PaywallViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let premium = PremiumService.shared
    
    // MARK: - Published State
    @Published var selectedPlan: SubscriptionPlan = .yearly
    @Published var trialEnabled: Bool = true
    @Published var isLoading: Bool = false
    
    // MARK: - Plans
    let plans = SubscriptionPlan.all
    let features = PremiumFeature.all
    
    // MARK: - Actions
    func selectPlan(_ plan: SubscriptionPlan) {
        selectedPlan = plan
    }
    
    func toggleTrial() {
        trialEnabled.toggle()
    }
    
    func purchase() async -> Bool {
        isLoading = true
        
        // Simulate purchase delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let success = await premium.handlePurchase(planId: selectedPlan.id)
        
        isLoading = false
        return success
    }
    
    func restore() async -> Bool {
        isLoading = true
        
        let success = await premium.restorePurchases()
        
        isLoading = false
        return success
    }
}

