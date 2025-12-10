import Foundation
import Combine
import RevenueCat

// MARK: - Premium Service
final class PremiumService: NSObject, ObservableObject {
    static let shared = PremiumService()
    
    private let storage = LocalStorageService.shared
    
    // MARK: - RevenueCat Configuration
    struct Config {
        static let apiKey = "appl_bDbfydrvxEqoWAvaZPwQeWoWCtY"
        static let entitlementId = "premium"
        
        // Product IDs
        static let weeklyId = "aclio_premium_weekly"
        static let monthlyId = "aclio_premium_monthly"
        static let yearlyId = "aclio_premium_yearly"
    }
    
    // MARK: - Published State
    @Published private(set) var isPremium: Bool = false
    @Published var showPaywall: Bool = false
    @Published private(set) var offerings: Offerings?
    @Published private(set) var currentOffering: Offering?
    @Published private(set) var isLoading: Bool = false
    @Published private(set) var error: String?
    
    // MARK: - Initialization
    private override init() {
        super.init()
        // Load cached premium status (will be verified with RevenueCat)
        let cachedPremium = storage.isPremium
        isPremium = cachedPremium
        print("📦 PremiumService: Initialized with cached premium = \(cachedPremium)")
    }
    
    // MARK: - Configure RevenueCat
    func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Config.apiKey)
        
        // Set delegate
        Purchases.shared.delegate = self
        
        print("📦 RevenueCat: Configured with API key")
        
        // Check subscription status on launch - this will verify/override cached status
        Task {
            await checkSubscriptionStatus()
            await fetchOfferings()
        }
    }
    
    // MARK: - Clear Premium (for testing)
    func clearPremiumStatus() {
        print("📦 PremiumService: Clearing premium status")
        setPremium(false)
    }
    
    // MARK: - Fetch Offerings
    @MainActor
    func fetchOfferings() async {
        isLoading = true
        error = nil
        
        do {
            offerings = try await Purchases.shared.offerings()
            currentOffering = offerings?.current
            print("📦 RevenueCat: Fetched offerings - \(offerings?.all.count ?? 0) available")
            if let current = currentOffering {
                print("📦 RevenueCat: Current offering has \(current.availablePackages.count) packages")
            }
        } catch {
            print("❌ RevenueCat: Failed to fetch offerings - \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    // MARK: - Check Subscription Status
    @MainActor
    func checkSubscriptionStatus() async {
        print("📦 RevenueCat: Checking subscription status...")
        
        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            
            // Log all entitlements for debugging
            print("📦 RevenueCat: Customer entitlements: \(customerInfo.entitlements.all.keys)")
            
            if let premiumEntitlement = customerInfo.entitlements[Config.entitlementId] {
                print("📦 RevenueCat: Entitlement '\(Config.entitlementId)' found")
                print("📦 RevenueCat: - isActive: \(premiumEntitlement.isActive)")
                print("📦 RevenueCat: - productIdentifier: \(premiumEntitlement.productIdentifier)")
                print("📦 RevenueCat: - expirationDate: \(premiumEntitlement.expirationDate?.description ?? "nil")")
                
                setPremium(premiumEntitlement.isActive)
            } else {
                print("📦 RevenueCat: No '\(Config.entitlementId)' entitlement found - setting premium to false")
                setPremium(false)
            }
        } catch {
            print("❌ RevenueCat: Failed to check subscription - \(error.localizedDescription)")
            // Don't change premium status on error - keep cached value
        }
    }
    
    // MARK: - Purchase
    @MainActor
    func purchase(package: Package) async -> Bool {
        isLoading = true
        error = nil
        
        print("📦 RevenueCat: Starting purchase for package: \(package.identifier)")
        print("📦 RevenueCat: Product ID: \(package.storeProduct.productIdentifier)")
        
        do {
            let result = try await Purchases.shared.purchase(package: package)
            
            print("📦 RevenueCat: Purchase completed - userCancelled: \(result.userCancelled)")
            
            if !result.userCancelled {
                let isActive = result.customerInfo.entitlements[Config.entitlementId]?.isActive ?? false
                print("📦 RevenueCat: Entitlement '\(Config.entitlementId)' isActive: \(isActive)")
                
                // Only grant premium if entitlement is actually active
                if isActive {
                    setPremium(true)
                    showPaywall = false
                    print("✅ RevenueCat: Purchase successful - Premium granted")
                    isLoading = false
                    return true
                } else {
                    print("⚠️ RevenueCat: Purchase completed but entitlement not active")
                    self.error = "Purchase completed but subscription not activated. Please try again."
                }
            } else {
                print("📦 RevenueCat: Purchase cancelled by user")
            }
        } catch {
            print("❌ RevenueCat: Purchase failed - \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
        return false
    }
    
    // MARK: - Restore Purchases
    @MainActor
    func restorePurchases() async -> Bool {
        isLoading = true
        error = nil
        
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            let isActive = customerInfo.entitlements[Config.entitlementId]?.isActive ?? false
            
            setPremium(isActive)
            print("✅ RevenueCat: Restore complete - Premium = \(isActive)")
            
            if isActive {
                showPaywall = false
            }
            
            isLoading = false
            return isActive
        } catch {
            print("❌ RevenueCat: Restore failed - \(error.localizedDescription)")
            self.error = error.localizedDescription
        }
        
        isLoading = false
        return false
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
            canUse = true
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
    
    // MARK: - Legacy Support (for backward compatibility)
    
    func handlePurchase(planId: String) async -> Bool {
        // Find the package by product ID
        guard let offering = currentOffering else {
            await fetchOfferings()
            guard let offering = currentOffering else { return false }
            
            if let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == planId }) {
                return await purchase(package: package)
            }
            return false
        }
        
        if let package = offering.availablePackages.first(where: { $0.storeProduct.productIdentifier == planId }) {
            return await purchase(package: package)
        }
        
        return false
    }
}

// MARK: - RevenueCat Delegate
extension PremiumService: PurchasesDelegate {
    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        Task { @MainActor in
            let isActive = customerInfo.entitlements[Config.entitlementId]?.isActive ?? false
            print("📦 RevenueCat: Customer info updated - Premium = \(isActive)")
            setPremium(isActive)
        }
    }
}

// MARK: - Package Helpers
extension Package {
    var periodName: String {
        switch packageType {
        case .weekly: return "Weekly"
        case .monthly: return "Monthly"
        case .annual: return "Yearly"
        default: return storeProduct.subscriptionPeriod?.periodTitle ?? "Unknown"
        }
    }
    
    var isBestValue: Bool {
        packageType == .annual
    }
}

extension SubscriptionPeriod {
    var periodTitle: String {
        switch unit {
        case .day: return value == 7 ? "Weekly" : "\(value) Days"
        case .week: return value == 1 ? "Weekly" : "\(value) Weeks"
        case .month: return value == 1 ? "Monthly" : "\(value) Months"
        case .year: return value == 1 ? "Yearly" : "\(value) Years"
        @unknown default: return "Unknown"
        }
    }
}
