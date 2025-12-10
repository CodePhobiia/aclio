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
    
    // MARK: - Static Features
    let features = PremiumFeature.all
    
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
            .assign(to: &$error)
    }
    
    // MARK: - Load Packages
    private func loadPackages() {
        if let offering = premium.currentOffering {
            updatePackages(from: offering)
        } else {
            Task {
                await premium.fetchOfferings()
            }
        }
    }
    
    private func updatePackages(from offering: Offering?) {
        guard let offering = offering else { return }
        
        // Sort packages: yearly first (best value), then monthly, then weekly
        packages = offering.availablePackages.sorted { p1, p2 in
            let order: [PackageType] = [.annual, .monthly, .weekly]
            let idx1 = order.firstIndex(of: p1.packageType) ?? 99
            let idx2 = order.firstIndex(of: p2.packageType) ?? 99
            return idx1 < idx2
        }
        
        // Default to yearly (best value)
        if selectedPackage == nil {
            selectedPackage = packages.first(where: { $0.packageType == .annual }) ?? packages.first
        }
    }
    
    // MARK: - Actions
    func selectPackage(_ package: Package) {
        selectedPackage = package
    }
    
    func purchase() async -> Bool {
        guard let package = selectedPackage else { return false }
        return await premium.purchase(package: package)
    }
    
    func restore() async -> Bool {
        return await premium.restorePurchases()
    }
    
    // MARK: - Display Helpers
    var selectedPrice: String {
        selectedPackage?.localizedPriceString ?? "$9.99"
    }
    
    var selectedPeriod: String {
        selectedPackage?.periodName ?? "Yearly"
    }
    
    var selectedPeriodLabel: String {
        switch selectedPackage?.packageType {
        case .weekly: return "week"
        case .monthly: return "month"
        case .annual: return "year"
        default: return "month"
        }
    }
}

// MARK: - Package Display Extension
extension Package: Identifiable {
    public var id: String { identifier }
}
