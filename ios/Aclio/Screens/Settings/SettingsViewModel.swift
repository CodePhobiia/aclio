import Foundation
import CoreLocation
import Combine

// MARK: - Settings View Model
@MainActor
final class SettingsViewModel: NSObject, ObservableObject {
    
    // MARK: - Dependencies
    private let storage = LocalStorageService.shared
    private let premium = PremiumService.shared
    
    // MARK: - Published State
    @Published var profile: UserProfile = UserProfile()
    @Published var isDarkMode: Bool = false
    @Published var notificationsEnabled: Bool = false
    @Published var location: LocationData?
    @Published var locationLoading: Bool = false
    @Published var showLogoutConfirm: Bool = false
    
    // MARK: - Premium
    var isPremium: Bool { premium.isPremium }
    var showPaywall: Bool {
        get { premium.showPaywall }
        set { premium.showPaywall = newValue }
    }
    
    // MARK: - Location Manager
    private var locationManager: CLLocationManager?
    
    // MARK: - Initialization
    override init() {
        super.init()
        loadData()
    }
    
    // MARK: - Load Data
    func loadData() {
        profile = storage.loadProfile() ?? UserProfile()
        isDarkMode = storage.loadTheme()
        notificationsEnabled = storage.notificationsEnabled
        location = storage.loadLocation()
    }
    
    // MARK: - Theme
    func toggleTheme() {
        isDarkMode.toggle()
        storage.saveTheme(isDarkMode)
    }
    
    // MARK: - Notifications
    func toggleNotifications() {
        notificationsEnabled.toggle()
        storage.notificationsEnabled = notificationsEnabled
        
        if notificationsEnabled {
            // Request notification permission
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                Task { @MainActor in
                    if !granted {
                        self.notificationsEnabled = false
                        self.storage.notificationsEnabled = false
                    }
                }
            }
        }
    }
    
    // MARK: - Location
    func fetchLocation() {
        locationLoading = true
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager?.requestWhenInUseAuthorization()
    }
    
    func clearLocation() {
        location = nil
        storage.saveLocation(nil)
    }
    
    // MARK: - Logout
    func logout() {
        storage.resetOnboarding()
        // Note: Clear all data is handled by navigation reset
    }
}

// MARK: - Location Manager Delegate
extension SettingsViewModel: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        Task { @MainActor in
            // Reverse geocode
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                if let placemark = placemarks.first {
                    let locationData = LocationData(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        city: placemark.locality,
                        country: placemark.country,
                        displayName: [placemark.locality, placemark.country].compactMap { $0 }.joined(separator: ", ")
                    )
                    self.location = locationData
                    self.storage.saveLocation(locationData)
                }
            } catch {
                // Just save coordinates
                let locationData = LocationData(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude
                )
                self.location = locationData
                self.storage.saveLocation(locationData)
            }
            
            self.locationLoading = false
            self.locationManager?.stopUpdatingLocation()
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                manager.startUpdatingLocation()
            case .denied, .restricted:
                self.locationLoading = false
            default:
                break
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationLoading = false
        }
    }
}

