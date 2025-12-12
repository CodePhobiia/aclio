import SwiftUI
import UIKit

// MARK: - App Delegate
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Start analytics session
        Task { @MainActor in
            AnalyticsService.shared.track(AnalyticsEventName.appLaunched)
        }
        
        // Add breadcrumb
        Task { @MainActor in
            CrashReportingService.shared.addBreadcrumb("App launched")
        }
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
    
    // Handle shortcut items
    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        Task { @MainActor in
            let handled = DeepLinkService.shared.handleShortcut(shortcutItem)
            completionHandler(handled)
        }
    }
}

// MARK: - Scene Delegate
class SceneDelegate: NSObject, UIWindowSceneDelegate {
    
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        // Handle URL if app was launched via deep link
        if let url = connectionOptions.urlContexts.first?.url {
            Task { @MainActor in
                _ = DeepLinkService.shared.handle(url: url)
            }
        }
        
        // Handle shortcut if app was launched via quick action
        if let shortcutItem = connectionOptions.shortcutItem {
            Task { @MainActor in
                _ = DeepLinkService.shared.handleShortcut(shortcutItem)
            }
        }
    }
    
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        Task { @MainActor in
            _ = DeepLinkService.shared.handle(url: url)
        }
    }
    
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        Task { @MainActor in
            _ = DeepLinkService.shared.handleUserActivity(userActivity)
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        Task { @MainActor in
            AnalyticsService.shared.track(AnalyticsEventName.appForegrounded)
            NotificationService.shared.clearBadge()
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        Task { @MainActor in
            AnalyticsService.shared.track(AnalyticsEventName.appBackgrounded)
        }
    }
}

// MARK: - App Entry Point
@main
struct AclioApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    @StateObject private var appState = AppState()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var featureFlags = FeatureFlagService.shared
    
    init() {
        // Run data migrations
        DataMigrationService.shared.runOnAppLaunch()
        
        // Configure RevenueCat
        PremiumService.shared.configure()
        
        // Initialize crash reporting
        Task { @MainActor in
            CrashReportingService.shared.addBreadcrumb("App initialized")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(networkMonitor)
                .environmentObject(featureFlags)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
                .onOpenURL { url in
                    _ = DeepLinkService.shared.handle(url: url)
                }
                .onReceive(NotificationCenter.default.publisher(for: .deepLinkNavigation)) { notification in
                    handleDeepLinkNavigation(notification)
                }
                .onReceive(NotificationCenter.default.publisher(for: .openGoalFromNotification)) { notification in
                    handleNotificationNavigation(notification)
                }
        }
    }
    
    private func handleDeepLinkNavigation(_ notification: Notification) {
        guard let route = notification.object as? DeepLinkRoute else { return }
        
        Task { @MainActor in
            // Ensure we're on dashboard first
            if appState.currentScreen != .dashboard {
                appState.navigateToRoot(.dashboard)
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            
            switch route {
            case .dashboard:
                break // Already there
            case .newGoal:
                appState.navigate(to: .newGoal)
            case .goalDetail(let goalId):
                if let goal = LocalStorageService.shared.loadGoals().first(where: { $0.id == goalId }) {
                    appState.navigate(to: .goalDetail(goal))
                }
            case .chat(let goalId):
                let goal = goalId.flatMap { id in
                    LocalStorageService.shared.loadGoals().first { $0.id == id }
                }
                appState.navigate(to: .chat(goal))
            case .settings:
                appState.navigate(to: .settings)
            case .premium:
                PremiumService.shared.showPaywall = true
            case .profile:
                appState.navigate(to: .editProfile)
            }
            
            DeepLinkService.shared.clearPendingRoute()
        }
    }
    
    private func handleNotificationNavigation(_ notification: Notification) {
        guard let goalId = notification.object as? Int else { return }
        
        Task { @MainActor in
            if let goal = LocalStorageService.shared.loadGoals().first(where: { $0.id == goalId }) {
                if appState.currentScreen != .dashboard {
                    appState.navigateToRoot(.dashboard)
                    try? await Task.sleep(nanoseconds: 100_000_000)
                }
                appState.navigate(to: .goalDetail(goal))
            }
        }
    }
}

// MARK: - App State
@MainActor
final class AppState: ObservableObject {
    
    // MARK: - Dependencies
    private let storage = LocalStorageService.shared
    
    // MARK: - Navigation State
    @Published var currentScreen: AppScreen = .loading
    @Published var navigationPath: [AppScreen] = []
    
    // MARK: - Shared State
    @Published var activeGoal: Goal?
    @Published var isDarkMode: Bool = false
    @Published var profile: UserProfile = UserProfile()
    
    // MARK: - Initialization
    init() {
        loadInitialState()
        observeThemeChanges()
    }
    
    private func observeThemeChanges() {
        NotificationCenter.default.addObserver(
            forName: .themeChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let isDark = notification.object as? Bool {
                self?.isDarkMode = isDark
            } else {
                self?.refreshTheme()
            }
        }
    }
    
    private func loadInitialState() {
        isDarkMode = storage.loadTheme()
        profile = storage.loadProfile() ?? UserProfile()
        
        // Determine initial screen
        Task {
            // Simulate brief loading
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            if storage.hasOnboarded {
                currentScreen = .dashboard
            } else {
                currentScreen = .welcome
            }
        }
    }
    
    // MARK: - Navigation
    func navigate(to screen: AppScreen) {
        navigationPath.append(screen)
    }
    
    func navigateBack() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func navigateToRoot(_ screen: AppScreen) {
        navigationPath.removeAll()
        currentScreen = screen
    }
    
    func completeOnboarding() {
        storage.completeOnboarding()
        navigateToRoot(.dashboard)
    }
    
    func logout() {
        storage.resetOnboarding()
        navigationPath.removeAll()
        currentScreen = .welcome
    }
    
    func setActiveGoal(_ goal: Goal) {
        activeGoal = goal
    }
    
    func refreshProfile() {
        profile = storage.loadProfile() ?? UserProfile()
    }
    
    func refreshTheme() {
        isDarkMode = storage.loadTheme()
    }
}

// MARK: - App Screen Enum
enum AppScreen: Hashable {
    case loading
    case welcome
    case onboarding
    case profileSetup
    case dashboard
    case newGoal
    case goalDetail(Goal)
    case chat(Goal?)
    case settings
    case editProfile
    case analytics
    case devSettings
    case notificationSettings
    
    static func == (lhs: AppScreen, rhs: AppScreen) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading),
             (.welcome, .welcome),
             (.onboarding, .onboarding),
             (.profileSetup, .profileSetup),
             (.dashboard, .dashboard),
             (.newGoal, .newGoal),
             (.settings, .settings),
             (.editProfile, .editProfile),
             (.analytics, .analytics),
             (.devSettings, .devSettings),
             (.notificationSettings, .notificationSettings):
            return true
        case let (.goalDetail(g1), .goalDetail(g2)):
            return g1.id == g2.id
        case let (.chat(g1), .chat(g2)):
            return g1?.id == g2?.id
        default:
            return false
        }
    }
    
    func hash(into hasher: inout Hasher) {
        switch self {
        case .loading: hasher.combine("loading")
        case .welcome: hasher.combine("welcome")
        case .onboarding: hasher.combine("onboarding")
        case .profileSetup: hasher.combine("profileSetup")
        case .dashboard: hasher.combine("dashboard")
        case .newGoal: hasher.combine("newGoal")
        case .goalDetail(let goal): hasher.combine("goalDetail-\(goal.id)")
        case .chat(let goal): hasher.combine("chat-\(goal?.id ?? 0)")
        case .settings: hasher.combine("settings")
        case .editProfile: hasher.combine("editProfile")
        case .analytics: hasher.combine("analytics")
        case .devSettings: hasher.combine("devSettings")
        case .notificationSettings: hasher.combine("notificationSettings")
        }
    }
}

// MARK: - Content View (Root Navigation)
struct ContentView: View {
    
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            rootView
                .navigationDestination(for: AppScreen.self) { screen in
                    destinationView(for: screen)
                }
        }
        .animation(.easeInOut(duration: 0.3), value: appState.currentScreen)
    }
    
    @ViewBuilder
    private var rootView: some View {
        switch appState.currentScreen {
        case .loading:
            LoadingView()
            
        case .welcome:
            WelcomeView(
                onGetStarted: {
                    appState.navigate(to: .onboarding)
                },
                onSkip: {
                    appState.completeOnboarding()
                }
            )
            
        case .onboarding:
            OnboardingView(
                onComplete: {
                    appState.navigate(to: .profileSetup)
                },
                onSkip: {
                    appState.navigate(to: .profileSetup)
                }
            )
            
        case .profileSetup:
            ProfileSetupView(
                profile: $appState.profile,
                onComplete: {
                    appState.completeOnboarding()
                },
                onSkip: {
                    appState.completeOnboarding()
                }
            )
            
        case .dashboard:
            DashboardView(
                onNavigateToNewGoal: {
                    appState.navigate(to: .newGoal)
                },
                onNavigateToGoalDetail: { goal in
                    appState.setActiveGoal(goal)
                    appState.navigate(to: .goalDetail(goal))
                },
                onNavigateToSettings: {
                    appState.navigate(to: .settings)
                },
                onNavigateToAnalytics: {
                    appState.navigate(to: .analytics)
                }
            )
            
        default:
            DashboardView(
                onNavigateToNewGoal: {},
                onNavigateToGoalDetail: { _ in },
                onNavigateToSettings: {},
                onNavigateToAnalytics: {}
            )
        }
    }
    
    @ViewBuilder
    private func destinationView(for screen: AppScreen) -> some View {
        switch screen {
        case .onboarding:
            OnboardingView(
                onComplete: {
                    appState.navigate(to: .profileSetup)
                },
                onSkip: {
                    appState.navigate(to: .profileSetup)
                }
            )
            .navigationBarHidden(true)
            
        case .profileSetup:
            ProfileSetupView(
                profile: $appState.profile,
                onComplete: {
                    appState.completeOnboarding()
                },
                onSkip: {
                    appState.completeOnboarding()
                }
            )
            .navigationBarHidden(true)
            
        case .newGoal:
            NewGoalView(
                onBack: {
                    appState.navigateBack()
                },
                onGoalCreated: { goal in
                    appState.setActiveGoal(goal)
                    appState.navigateBack()
                    // Navigate to goal detail after a brief delay
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                        appState.navigate(to: .goalDetail(goal))
                    }
                }
            )
            .navigationBarHidden(true)
            
        case .goalDetail(let goal):
            GoalDetailView(
                goal: goal,
                onBack: {
                    appState.navigateBack()
                },
                onNavigateToChat: { chatGoal in
                    appState.navigate(to: .chat(chatGoal))
                },
                onDeleted: {
                    appState.navigateBack()
                }
            )
            .navigationBarHidden(true)
            
        case .chat(let goal):
            ChatView(
                goal: goal,
                onBack: {
                    appState.navigateBack()
                }
            )
            .navigationBarHidden(true)
            
        case .settings:
            SettingsView(
                onBack: {
                    appState.navigateBack()
                    appState.refreshTheme()
                },
                onNavigateToEditProfile: {
                    appState.navigate(to: .editProfile)
                },
                onNavigateToAnalytics: {
                    appState.navigate(to: .analytics)
                },
                onNavigateToNotifications: {
                    appState.navigate(to: .notificationSettings)
                },
                onNavigateToDevSettings: {
                    appState.navigate(to: .devSettings)
                },
                onLogout: {
                    appState.logout()
                }
            )
            .navigationBarHidden(true)
            
        case .editProfile:
            EditProfileView(
                onBack: {
                    appState.navigateBack()
                    appState.refreshProfile()
                }
            )
            .navigationBarHidden(true)
            
        case .analytics:
            AnalyticsView(
                onBack: {
                    appState.navigateBack()
                }
            )
            .navigationBarHidden(true)
            
        case .devSettings:
            DeveloperSettingsView(
                onBack: {
                    appState.navigateBack()
                }
            )
            .navigationBarHidden(true)
            
        case .notificationSettings:
            NotificationSettingsView(
                onBack: {
                    appState.navigateBack()
                }
            )
            .navigationBarHidden(true)
            
        default:
            EmptyView()
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            Color.aclioHeaderBg
                .ignoresSafeArea()
            
            VStack {
                MascotView(size: .large, showGlow: true)
                    .scaleEffect(isAnimating ? 1.05 : 0.95)
                    .animation(
                        .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
        .environmentObject(AppState())
}


