# iOS Setup Instructions for Aclio

This repo contains **two different iOS setups**:

- **Native SwiftUI app (recommended)**: `ios/Aclio` (generated via **XcodeGen**)
- **Capacitor wrapper**: `ios/App` (generated/managed via **Capacitor**)

If you’re seeing build errors referencing `ios/Aclio/AclioApp.swift`, you want the **Native SwiftUI** setup below.

## Native SwiftUI app (ios/Aclio) — XcodeGen

Run these commands in Terminal on your Mac:

```bash
cd ios
./setup-xcode-project.sh
open Aclio.xcodeproj
```

### Important: regenerate after pulling changes

If you pull new commits that add/move Swift files under `ios/Aclio/`, you must re-run:

```bash
cd ios
xcodegen generate --spec project.yml
```

Otherwise Xcode can fail with “Cannot find ___ in scope” because those files aren’t in the generated project yet.

Run these commands in Terminal on your Mac:

## Step 1: Install Dependencies

```bash
# Install Capacitor core and CLI
npm install @capacitor/core @capacitor/cli

# Install iOS platform
npm install @capacitor/ios

# Install RevenueCat Capacitor plugin
npm install @revenuecat/purchases-capacitor
```

## Step 2: Build the Web App

```bash
npm run build
```

## Step 3: Add iOS Platform

```bash
npx cap add ios
```

## Step 4: Sync Changes to iOS

```bash
npx cap sync ios
```

## Step 5: Open in Xcode

```bash
npx cap open ios
```

---

## In Xcode:

1. **Select your Team** in Signing & Capabilities
2. **Set Bundle Identifier** to: `com.ahmed.aclio`
3. **Add In-App Purchase capability**:
   - Click `+ Capability`
   - Add "In-App Purchase"

4. **Run on Simulator or Device**:
   - Select a simulator or connect your iPhone
   - Press `Cmd + R` to build and run

---

## Every Time You Make Changes:

```bash
npm run build
npx cap sync ios
npx cap open ios
```

Or use the shortcut:

```bash
npm run build && npx cap sync ios
```

---

## RevenueCat Setup in iOS

After opening in Xcode, you'll need to initialize RevenueCat.

Edit `ios/App/App/AppDelegate.swift` and add:

```swift
import UIKit
import Capacitor
import RevenueCat  // Add this import

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // Configure RevenueCat
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: "test_SYAgudByWWBeGBviXsVovsUbDMA")
        
        return true
    }
    
    // ... rest of the file
}
```

---

## Testing Subscriptions

1. Create a **Sandbox Tester** in App Store Connect:
   - Users and Access → Sandbox → Testers → Add

2. On your iPhone:
   - Settings → App Store → Sandbox Account
   - Sign in with your sandbox tester

3. Purchases in sandbox mode are free and auto-renew quickly for testing

---

## Product IDs (already set up in App Store Connect):

- `aclio_premium_weekly` - $2.99/week
- `aclio_premium_monthly` - $7.99/month  
- `aclio_premium_yearly` - $49.99/year

---

## Troubleshooting

**"No products found"**: Make sure products in App Store Connect have all required metadata and your Paid Apps agreement is signed.

**Signing errors**: Select your Apple Developer team in Xcode's Signing & Capabilities.

**Build errors**: Try `npx cap sync ios` again, or delete the `ios` folder and run `npx cap add ios` again.







