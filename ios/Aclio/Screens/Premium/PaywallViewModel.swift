import Foundation
import Combine
import RevenueCat

// MARK: - Paywall View Model
@MainActor
final class PaywallViewModel: ObservableObject {
    
    // MARK: - Dependencies
    private let premium = PremiumService.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published State
    @Published var selectedPackage: Package?
    @Published var packages: [Package] = []
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    // Fallback to static plans when RevenueCat fails
    @Published var selectedStaticPlan: SubscriptionPlan = .yearly
    @Published var useStaticPlans: Bool = false
    
    // MARK: - Static Features
    let features = PremiumFeature.all
    let staticPlans = SubscriptionPlan.all
    
    // MARK: - Initialization
    init() {
        observePremiumService()
        loadPackages()
    }
    
    // MARK: - Observe Premium Service
    private func observePremiumService() {
        premium.$currentOffering
            .receive(on: DispatchQueue.main)
            .sink { [weak self] offering in
                self?.updatePackages(from: offering)
            }
            .store(in: &cancellables)
        
        premium.$isLoading
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
        
        premium.$error
            .receive(on: DispatchQueue.main)
            .sink { [weak self] error in
                if error != nil {
                    // RevenueCat failed, use static plans
                    self?.useStaticPlans = true
                }
                self?.error = error
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Load Packages
    private func loadPackages() {
        if let offering = premium.currentOffering {
            updatePackages(from: offering)
        } else {
            Task {
                await premium.fetchOfferings()
                
                // If still no packages after fetch, use static plans
                if packages.isEmpty {
                    useStaticPlans = true
                }
            }
        }
    }
    
    private func updatePackages(from offering: Offering?) {
        guard let offering = offering else {
            useStaticPlans = true
            return
        }
        
        // Sort packages: weekly first, then monthly, then yearly (left to right, small to big)
        packages = offering.availablePackages.sorted { p1, p2 in
            let order: [PackageType] = [.weekly, .monthly, .annual]
            let idx1 = order.firstIndex(of: p1.packageType) ?? 99
            let idx2 = order.firstIndex(of: p2.packageType) ?? 99
            return idx1 < idx2
        }
        
        if packages.isEmpty {
            useStaticPlans = true
        } else {
            useStaticPlans = false
            // Default to yearly (best value)
            if selectedPackage == nil {
                selectedPackage = packages.first(where: { $0.packageType == .annual }) ?? packages.first
            }
        }
    }
    
    // MARK: - Actions
    func selectPackage(_ package: Package) {
        selectedPackage = package
    }
    
    func selectStaticPlan(_ plan: SubscriptionPlan) {
        selectedStaticPlan = plan
    }
    
    func purchase() async -> Bool {
        if useStaticPlans {
            // Use static plan ID to find package, or just grant premium for testing
            let productId = "aclio_premium_\(selectedStaticPlan.id)"
            return await premium.handlePurchase(planId: productId)
        }
        
        guard let package = selectedPackage else { return false }
        return await premium.purchase(package: package)
    }
    
    func restore() async -> Bool {
        return await premium.restorePurchases()
    }
    
    // MARK: - Display Helpers
    var selectedPrice: String {
        if useStaticPlans {
            return selectedStaticPlan.price
        }
        return selectedPackage?.localizedPriceString ?? "$49.99"
    }
    
    var selectedPeriod: String {
        if useStaticPlans {
            return selectedStaticPlan.period
        }
        return selectedPackage?.periodName ?? "Yearly"
    }
    
    var selectedPeriodLabel: String {
        if useStaticPlans {
            return selectedStaticPlan.periodLabel
        }
        switch selectedPackage?.packageType {
        case .weekly: return "week"
        case .monthly: return "month"
        case .annual: return "year"
        default: return "year"
        }
    }
}

