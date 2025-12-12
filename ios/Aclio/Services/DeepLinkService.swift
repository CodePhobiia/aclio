import Foundation
import UIKit

// MARK: - Deep Link Route
/// Represents all possible deep link destinations in the app
enum DeepLinkRoute: Equatable {
    case dashboard
    case newGoal
    case goalDetail(goalId: Int)
    case chat(goalId: Int?)
    case settings
    case premium
    case profile
    
    /// URL path for this route
    var path: String {
        switch self {
        case .dashboard:
            return "/dashboard"
        case .newGoal:
            return "/goal/new"
        case .goalDetail(let goalId):
            return "/goal/\(goalId)"
        case .chat(let goalId):
            if let id = goalId {
                return "/chat/\(id)"
            }
            return "/chat"
        case .settings:
            return "/settings"
        case .premium:
            return "/premium"
        case .profile:
            return "/profile"
        }
    }
    
    /// Creates a full URL for this route
    func url(scheme: String = DeepLinkService.urlScheme) -> URL? {
        URL(string: "\(scheme)://\(DeepLinkService.host)\(path)")
    }
}

// MARK: - Deep Link Service
/// Handles deep linking via URL schemes and universal links.
///
/// Supported URL formats:
/// - Custom URL Scheme: `aclio://app/goal/123`
/// - Universal Link: `https://aclio.app/goal/123`
///
/// Usage:
/// ```swift
/// // Parse incoming URL
/// if let route = DeepLinkService.shared.parse(url: incomingURL) {
///     DeepLinkService.shared.navigate(to: route)
/// }
///
/// // Generate shareable URL
/// let shareURL = DeepLinkRoute.goalDetail(goalId: 123).url()
/// ```
@MainActor
final class DeepLinkService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = DeepLinkService()
    
    // MARK: - Configuration
    nonisolated static let urlScheme = "aclio"
    nonisolated static let host = "app"
    nonisolated static let universalLinkHost = "aclio.app"
    
    // MARK: - State
    @Published var pendingRoute: DeepLinkRoute?
    @Published var lastHandledURL: URL?
    
    // MARK: - Dependencies
    private let analytics = AnalyticsService.shared
    
    private init() {}
    
    // MARK: - URL Parsing
    
    /// Parses a URL and returns the corresponding route
    func parse(url: URL) -> DeepLinkRoute? {
        // Handle custom URL scheme (aclio://app/...)
        if url.scheme == Self.urlScheme {
            return parseCustomScheme(url)
        }
        
        // Handle universal links (https://aclio.app/...)
        if url.host == Self.universalLinkHost || url.host == "www.\(Self.universalLinkHost)" {
            return parseUniversalLink(url)
        }
        
        return nil
    }
    
    private func parseCustomScheme(_ url: URL) -> DeepLinkRoute? {
        guard url.scheme == Self.urlScheme else { return nil }
        
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        return parsePathComponents(pathComponents, queryItems: URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
    }
    
    private func parseUniversalLink(_ url: URL) -> DeepLinkRoute? {
        let pathComponents = url.pathComponents.filter { $0 != "/" }
        return parsePathComponents(pathComponents, queryItems: URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
    }
    
    private func parsePathComponents(_ components: [String], queryItems: [URLQueryItem]?) -> DeepLinkRoute? {
        guard !components.isEmpty else {
            return .dashboard
        }
        
        switch components[0] {
        case "dashboard":
            return .dashboard
            
        case "goal":
            if components.count > 1 {
                if components[1] == "new" {
                    return .newGoal
                } else if let goalId = Int(components[1]) {
                    return .goalDetail(goalId: goalId)
                }
            }
            return .newGoal
            
        case "chat":
            if components.count > 1, let goalId = Int(components[1]) {
                return .chat(goalId: goalId)
            }
            // Check query parameter
            if let goalIdString = queryItems?.first(where: { $0.name == "goal" })?.value,
               let goalId = Int(goalIdString) {
                return .chat(goalId: goalId)
            }
            return .chat(goalId: nil)
            
        case "settings":
            return .settings
            
        case "premium", "upgrade":
            return .premium
            
        case "profile":
            return .profile
            
        default:
            return nil
        }
    }
    
    // MARK: - Navigation
    
    /// Handles a deep link URL and navigates accordingly
    func handle(url: URL) -> Bool {
        guard let route = parse(url: url) else {
            print("⚠️ DeepLink: Unable to parse URL - \(url)")
            return false
        }
        
        lastHandledURL = url
        navigate(to: route)
        
        // Track analytics
        analytics.track("deep_link_opened", parameters: [
            "url": url.absoluteString,
            "route": route.path
        ])
        
        return true
    }
    
    /// Navigates to a specific route
    func navigate(to route: DeepLinkRoute) {
        pendingRoute = route
        
        // Post notification for app to handle navigation
        NotificationCenter.default.post(
            name: .deepLinkNavigation,
            object: route
        )
        
        print("🔗 DeepLink: Navigating to \(route.path)")
    }
    
    /// Clears the pending route after it's been handled
    func clearPendingRoute() {
        pendingRoute = nil
    }
    
    // MARK: - URL Generation
    
    /// Generates a shareable deep link URL for a goal
    func shareURL(for goal: Goal) -> URL? {
        DeepLinkRoute.goalDetail(goalId: goal.id).url()
    }
    
    /// Generates a universal link URL (for web sharing)
    func universalShareURL(for goal: Goal) -> URL? {
        URL(string: "https://\(Self.universalLinkHost)/goal/\(goal.id)")
    }
    
    // MARK: - Shortcut Items
    
    /// Creates quick action items for the home screen
    func createShortcutItems() -> [UIApplicationShortcutItem] {
        [
            UIApplicationShortcutItem(
                type: "com.aclio.newgoal",
                localizedTitle: "New Goal",
                localizedSubtitle: "Create a new goal",
                icon: UIApplicationShortcutIcon(systemImageName: "plus.circle.fill"),
                userInfo: ["route": "goal/new" as NSString]
            ),
            UIApplicationShortcutItem(
                type: "com.aclio.chat",
                localizedTitle: "Chat with Aclio",
                localizedSubtitle: "Get AI coaching",
                icon: UIApplicationShortcutIcon(systemImageName: "bubble.left.and.bubble.right.fill"),
                userInfo: ["route": "chat" as NSString]
            )
        ]
    }
    
    /// Handles a shortcut item action
    func handleShortcut(_ shortcutItem: UIApplicationShortcutItem) -> Bool {
        guard let routeString = shortcutItem.userInfo?["route"] as? String else {
            return false
        }
        
        // Parse the route string
        let components = routeString.split(separator: "/").map(String.init)
        if let route = parsePathComponents(components, queryItems: nil) {
            navigate(to: route)
            return true
        }
        
        return false
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let deepLinkNavigation = Notification.Name("deepLinkNavigation")
}

// MARK: - Scene Delegate Extension (for handling URLs)
extension DeepLinkService {
    
    /// Handle URL opened via URL scheme
    func handleURLOpen(_ url: URL) -> Bool {
        handle(url: url)
    }
    
    /// Handle user activity (universal links)
    func handleUserActivity(_ userActivity: NSUserActivity) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }
        
        return handle(url: url)
    }
}

// MARK: - SwiftUI Integration
import SwiftUI

/// View modifier for handling deep links
struct DeepLinkHandlerModifier: ViewModifier {
    @StateObject private var deepLinkService = DeepLinkService.shared
    let onNavigate: (DeepLinkRoute) -> Void
    
    func body(content: Content) -> some View {
        content
            .onOpenURL { url in
                _ = deepLinkService.handle(url: url)
            }
            .onReceive(NotificationCenter.default.publisher(for: .deepLinkNavigation)) { notification in
                if let route = notification.object as? DeepLinkRoute {
                    onNavigate(route)
                }
            }
    }
}

extension View {
    /// Adds deep link handling to a view
    func handleDeepLinks(onNavigate: @escaping (DeepLinkRoute) -> Void) -> some View {
        modifier(DeepLinkHandlerModifier(onNavigate: onNavigate))
    }
}

