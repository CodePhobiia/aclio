import SwiftUI

// MARK: - App Entry Point
@main
struct AclioApp: App {
    
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .preferredColorScheme(appState.isDarkMode ? .dark : .light)
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
             (.analytics, .analytics):
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
                onSignIn: {
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


