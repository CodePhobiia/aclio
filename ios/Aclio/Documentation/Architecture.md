# Aclio iOS Architecture Documentation

## Overview

Aclio is a native SwiftUI iOS application that helps users set and track goals with AI-powered action plans. This document describes the app's architecture, key components, and design decisions.

## Architecture Pattern

The app follows a **MVVM (Model-View-ViewModel)** architecture with **Service Layer** for business logic and data access.

```
┌─────────────────────────────────────────────────────────────┐
│                         Views                                │
│  (SwiftUI Views - UI only, no business logic)               │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      ViewModels                              │
│  (@MainActor, ObservableObject - UI state & coordination)   │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                       Services                               │
│  (Business logic, API calls, data persistence)              │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                        Models                                │
│  (Data structures - Codable, Equatable)                     │
└─────────────────────────────────────────────────────────────┘
```

## Directory Structure

```
ios/Aclio/
├── AclioApp.swift              # App entry point
├── Components/                 # Reusable UI components
│   ├── Cards/                  # Card-style components
│   ├── Buttons/                # Button components
│   └── ...
├── Models/                     # Data models
│   ├── Goal.swift              # Goal model
│   ├── UserProfile.swift       # User profile model
│   └── ...
├── Screens/                    # Feature screens
│   ├── Dashboard/              # Main dashboard
│   ├── GoalDetail/             # Goal detail view
│   ├── NewGoal/                # Goal creation flow
│   ├── Chat/                   # AI chat interface
│   └── ...
├── Services/                   # Business logic services
│   ├── ApiService.swift        # Backend API calls
│   ├── LocalStorageService.swift
│   ├── PremiumService.swift    # RevenueCat integration
│   ├── GamificationService.swift
│   └── ...
├── Theme/                      # Design system
│   ├── AclioColors.swift
│   ├── AclioFont.swift
│   └── ...
├── Utils/                      # Utility functions
│   ├── AppError.swift          # Error handling
│   ├── InputValidation.swift   # Input validation
│   ├── Localization.swift      # i18n support
│   └── ...
└── Resources/                  # Assets & localization
    ├── Assets.xcassets
    └── en.lproj/Localizable.strings
```

## Key Services

### ApiService

An `actor` that handles all backend API communication.

```swift
actor ApiService {
    static let shared = ApiService()
    
    func generateSteps(goal: String, ...) async throws -> GenerateStepsResponse
    func chatStream(message: String, ..., onChunk: @escaping (String) -> Void) async throws
}
```

**Key Features:**
- Singleton pattern for shared instance
- `actor` ensures thread-safe access
- Async/await for modern concurrency
- Streaming support for chat responses
- Automatic JSON encoding/decoding

### LocalStorageService

Handles all local data persistence using UserDefaults.

```swift
final class LocalStorageService {
    static let shared = LocalStorageService()
    
    func saveGoals(_ goals: [Goal])
    func loadGoals() -> [Goal]
    func saveProfile(_ profile: UserProfile)
    // ...
}
```

**Key Features:**
- JSON encoding/decoding for complex types
- Type-safe storage keys (enum)
- Offline-first approach

### PremiumService

Manages premium subscriptions via RevenueCat.

```swift
final class PremiumService: NSObject, ObservableObject {
    static let shared = PremiumService()
    
    @Published private(set) var isPremium: Bool = false
    @Published var showPaywall: Bool = false
    
    func canCreateGoal(currentCount: Int) -> Bool
    func purchase(package: Package) async -> Bool
}
```

**Key Features:**
- RevenueCat SDK integration
- Feature gating (canCreateGoal, canExpandStep, etc.)
- Daily usage limits for free tier
- Restore purchases support

### GamificationService

Handles points, levels, streaks, and achievements.

```swift
@MainActor
final class GamificationService: ObservableObject {
    @Published var points: Int = 0
    @Published var streak: StreakData
    @Published var currentLevel: Level
    
    func awardStepPoints()
    func awardGoalPoints()
    func claimDailyBonus() -> Int
}
```

**Key Features:**
- Point system (steps = 10pts, goals = 50pts)
- Level progression with milestones
- Daily streaks with persistence
- Achievement tracking

### AppStateManager

Centralized state management for app-wide data.

```swift
@MainActor
final class AppStateManager: ObservableObject {
    static let shared = AppStateManager()
    
    @Published private(set) var profile: UserProfile?
    @Published private(set) var goals: [Goal] = []
    @Published private(set) var isPremium: Bool = false
    // ...
}
```

**Key Features:**
- Single source of truth
- Coordinates between services
- Computed properties for derived state
- Thread-safe with @MainActor

## Data Flow

### Goal Creation Flow

```
1. User enters goal text in NewGoalView
2. NewGoalViewModel validates input (InputValidator)
3. On submit, ViewModel calls ApiService.generateSteps()
4. Backend returns AI-generated steps
5. ViewModel creates Goal model
6. Goal saved via LocalStorageService
7. GamificationService awards points
8. Navigate to GoalDetailView
```

### Chat Streaming Flow

```
1. User sends message in ChatView
2. ChatViewModel validates input
3. Creates placeholder assistant message (isStreaming: true)
4. Calls ApiService.chatStream() with SSE
5. Each chunk updates message content via MainActor
6. On completion, marks isStreaming: false
7. UI auto-scrolls to latest message
```

## Threading Model

- **@MainActor**: All ViewModels, UI-related services
- **actor**: ApiService (async network calls)
- **Main queue**: Combine publishers, UI updates
- **Background**: Network requests, JSON parsing

### Important Threading Rules

1. All `@Published` properties must be updated on MainActor
2. Use `await MainActor.run { }` for callbacks from background
3. ApiService uses `actor` for automatic thread safety
4. Never block main thread with synchronous work

## Error Handling

Errors are handled through the `AppError` enum:

```swift
enum AppError: LocalizedError, Identifiable {
    case networkError
    case serverError(String)
    case validationError(String)
    case timeout
    case rateLimited
    // ...
}
```

**Usage in ViewModels:**
```swift
@Published var error: AppError?

// In views:
.errorAlert($viewModel.error) {
    // retry action
}
```

## Premium Feature Gating

Free tier limits:
- 3 goals maximum
- 3 "Expand Step" uses per day
- 3 "Do It For Me" uses per day
- Unlimited chat

Premium unlocks:
- Unlimited goals
- Unlimited AI features
- Priority support

## Data Migration

The app uses a versioned migration system:

```swift
DataMigrationService.shared.runOnAppLaunch()
```

Migrations are defined as conforming to `Migration` protocol:

```swift
struct MigrationV2: Migration {
    var version: Int { 2 }
    var description: String { "Add metadata fields to goals" }
    func migrate() throws { ... }
}
```

## Offline Support

The app includes offline capabilities:

1. **NetworkMonitor**: Tracks connectivity state
2. **OfflineQueueService**: Queues operations when offline
3. **OfflineIndicator**: Visual feedback for users

Operations are automatically synced when connectivity returns.

## Testing Strategy

### Unit Tests

- `InputValidationTests`: Input validation logic
- `GoalTests`: Goal model behavior
- `PremiumServiceTests`: Feature gating logic

### UI Tests (Recommended)

- Onboarding flow
- Goal creation flow
- Step completion
- Premium purchase flow

## Performance Considerations

1. **LazyVStack**: Used for goal lists
2. **Equatable**: Goal model conforms for efficient diffing
3. **@StateObject**: Proper ownership in views
4. **Task cancellation**: Streaming tasks can be cancelled

## Accessibility

The app includes comprehensive accessibility support:

- VoiceOver labels and hints
- Accessibility announcements for state changes
- Custom accessibility actions
- Proper semantic grouping

See `AccessibilityHelpers.swift` for utilities.

## Localization

String localization is set up with:

- `Localizable.strings` for all user-facing text
- `L10n` enum for type-safe key access
- String extension for easy localization

```swift
// Usage:
Text("common.ok".localized)
Text(L10n.Common.ok.localized)
```

## Security

1. **API Keys**: RevenueCat key is public (by design)
2. **Backend API Key**: Stored on server, never in app
3. **User Data**: Stored locally in UserDefaults (device-encrypted)
4. **Network**: All API calls use HTTPS with TLS 1.2+

## Dependencies

- **RevenueCat**: In-app purchases
- **SwiftUI**: UI framework
- **Combine**: Reactive programming
- **Foundation**: Core utilities

No other external dependencies - keeping the app lightweight.

