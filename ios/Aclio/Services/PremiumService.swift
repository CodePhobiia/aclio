import Foundation
import Combine

// MARK: - Premium Service
final class PremiumService: ObservableObject {
    static let shared = PremiumService()
    
    private let storage = LocalStorageService.shared
    
    // MARK: - Published State
    @Published private(set) var isPremium: Bool = false
    @Published var showPaywall: Bool = false
    
    // MARK: - Initialization
    private init() {
        isPremium = storage.isPremium
    }
    
    // MARK: - Premium Status
    
    func setPremium(_ value: Bool) {
        isPremium = value
        storage.isPremium = value
    }
    
    // MARK: - Feature Gating
    
    func canCreateGoal(currentCount: Int) -> Bool {
        if isPremium { return true }
        return currentCount < PremiumConfig.freeGoalLimit
    }
    
    func canUseDoItForMe() -> Bool {
        if isPremium { return true }
        return storage.getRemainingUses(for: .doItForMe) > 0
    }
    
    func canExpandStep() -> Bool {
        if isPremium { return true }
        return storage.getRemainingUses(for: .expandStep) > 0
    }
    
    // MARK: - Use Premium Feature
    
    func usePremiumFeature(_ feature: PremiumFeatureType, onBlocked: (() -> Void)? = nil) -> Bool {
        var canUse = false
        
        switch feature {
        case .createGoal:
            // Note: This is checked with current goal count in canCreateGoal
            canUse = isPremium
        case .doItForMe:
            canUse = canUseDoItForMe()
            if canUse && !isPremium {
                _ = storage.incrementDailyUses(for: .doItForMe)
            }
        case .expandStep:
            canUse = canExpandStep()
            if canUse && !isPremium {
                _ = storage.incrementDailyUses(for: .expandStep)
            }
        case .chat:
            canUse = true // Chat is always available
        }
        
        if !canUse {
            showPaywall = true
            onBlocked?()
        }
        
        return canUse
    }
    
    // MARK: - Remaining Uses
    
    func getRemainingUses(for feature: PremiumFeatureType) -> Int {
        if isPremium { return .max }
        return storage.getRemainingUses(for: feature)
    }
    
    func getDoItForMeRemaining() -> Int {
        getRemainingUses(for: .doItForMe)
    }
    
    func getExpandRemaining() -> Int {
        getRemainingUses(for: .expandStep)
    }
    
    // MARK: - Goals Remaining
    
    func getGoalsRemaining(currentCount: Int) -> Int {
        if isPremium { return .max }
        return max(0, PremiumConfig.freeGoalLimit - currentCount)
    }
    
    // MARK: - Purchase Handling
    
    func handlePurchase(planId: String) async -> Bool {
        // TODO: Integrate with RevenueCat
        // For now, just set premium to true
        
        await MainActor.run {
            setPremium(true)
            showPaywall = false
        }
        
        return true
    }
    
    func restorePurchases() async -> Bool {
        // TODO: Integrate with RevenueCat restore
        
        // For now, check if premium was previously set
        return isPremium
    }
}

// MARK: - RevenueCat Integration (Placeholder)
extension PremiumService {
    
    // RevenueCat product IDs from memory
    struct RevenueCatConfig {
        static let apiKey = "appl_bDbfydrvxEqoWAvaZPwQeWoWCtY"
        static let weeklyId = "aclio_premium_weekly"
        static let monthlyId = "aclio_premium_monthly"
        static let yearlyId = "aclio_premium_yearly"
    }
    
    func configureRevenueCat() {
        // TODO: Initialize RevenueCat SDK
        // Purchases.configure(withAPIKey: RevenueCatConfig.apiKey)
    }
    
    func checkSubscriptionStatus() async {
        // TODO: Check RevenueCat entitlements
        // let customerInfo = try await Purchases.shared.customerInfo()
        // let isActive = customerInfo.entitlements["premium"]?.isActive ?? false
        // await MainActor.run { setPremium(isActive) }
    }
}


