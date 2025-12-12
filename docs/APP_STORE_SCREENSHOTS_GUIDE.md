# App Store Screenshots Guide - Aclio

## Required Screenshot Sizes

Since Aclio targets **iPhone only** (`TARGETED_DEVICE_FAMILY: "1"`), you need:

### iPhone 6.7" Display (Required)
- **Devices**: iPhone 15 Pro Max, iPhone 15 Plus, iPhone 14 Pro Max, iPhone 14 Plus
- **Resolution**: 1290 × 2796 pixels
- **Format**: PNG or JPEG

### iPhone 6.5" Display (Required)
- **Devices**: iPhone 11 Pro Max, iPhone XS Max
- **Resolution**: 1242 × 2688 pixels
- **Format**: PNG or JPEG

### iPhone 5.5" Display (Optional but recommended)
- **Devices**: iPhone 8 Plus, iPhone 7 Plus, iPhone 6s Plus
- **Resolution**: 1242 × 2208 pixels
- **Format**: PNG or JPEG

---

## Screenshot Content (8 Screenshots Recommended)

### Screenshot 1: Welcome/Onboarding
- **Screen**: `WelcomeView`
- **Show**: App logo, mascot, "Get Started" button
- **Message**: First impression, value proposition

### Screenshot 2: Dashboard
- **Screen**: `DashboardView`
- **Show**: Active goals with progress bars, streak counter, daily tasks
- **Message**: At-a-glance progress tracking

### Screenshot 3: Goal Creation
- **Screen**: `NewGoalView`
- **Show**: AI generating steps, goal input field
- **Message**: AI-powered planning

### Screenshot 4: Goal Detail
- **Screen**: `GoalDetailView`
- **Show**: Steps list with checkboxes, progress percentage, expand button
- **Message**: Step-by-step guidance

### Screenshot 5: Chat Feature
- **Screen**: `ChatView`
- **Show**: Conversation with AI coach, helpful response
- **Message**: Personal AI coaching

### Screenshot 6: Analytics
- **Screen**: `AnalyticsView`
- **Show**: Achievement badges, stats, streaks
- **Message**: Track your success

### Screenshot 7: Do It For Me Result
- **Screen**: `DoItForMeResultView` or `ExpandedContentView`
- **Show**: AI-generated detailed content
- **Message**: AI does the work for you

### Screenshot 8: Premium Paywall
- **Screen**: `PaywallView`
- **Show**: Premium features list, pricing options
- **Message**: Unlock unlimited potential

---

## How to Take Screenshots

### Method 1: Xcode Simulator (Recommended)

1. **Open project in Xcode**
   ```bash
   cd ios
   xed .
   ```

2. **Select simulator**
   - iPhone 15 Pro Max (for 6.7" screenshots)
   - iPhone 11 Pro Max (for 6.5" screenshots)

3. **Run the app**
   - Press `Cmd + R`

4. **Navigate to each screen and take screenshot**
   - Press `Cmd + S` to save screenshot
   - Screenshots save to Desktop by default

5. **Rename files**
   ```
   screenshot_1_welcome.png
   screenshot_2_dashboard.png
   screenshot_3_new_goal.png
   screenshot_4_goal_detail.png
   screenshot_5_chat.png
   screenshot_6_analytics.png
   screenshot_7_doitforme.png
   screenshot_8_premium.png
   ```

### Method 2: Real Device

1. **Connect iPhone to Mac**

2. **Run app on device**
   - Select device in Xcode
   - Press `Cmd + R`

3. **Take screenshots on device**
   - Press Side Button + Volume Up simultaneously

4. **Transfer to Mac**
   - AirDrop or sync via Photos

---

## Screenshot Checklist

### Before Taking Screenshots
- [ ] Use **light mode** (looks better in App Store)
- [ ] Set time to **9:41 AM** (Apple's standard)
- [ ] Full signal bars, WiFi, full battery
- [ ] Populate with **realistic demo data**:
  - 3-4 goals with varied progress
  - Some completed steps
  - Active streak (7+ days ideal)
  - Achievement badges unlocked

### Demo Data Setup

Add this data before taking screenshots:

**Goals to create:**
1. "Learn Spanish" - 60% complete, 4/7 steps done
2. "Run a Marathon" - 30% complete, 2/6 steps done
3. "Launch My Startup" - 10% complete, 1/8 steps done

**Chat history:**
- User: "How do I stay motivated?"
- AI: "Great question! Here are 3 proven strategies..."

---

## Directory Structure

```
screenshots/
├── iphone_6_7/
│   ├── screenshot_1_welcome.png
│   ├── screenshot_2_dashboard.png
│   ├── screenshot_3_new_goal.png
│   ├── screenshot_4_goal_detail.png
│   ├── screenshot_5_chat.png
│   ├── screenshot_6_analytics.png
│   ├── screenshot_7_doitforme.png
│   └── screenshot_8_premium.png
├── iphone_6_5/
│   └── [same 8 screenshots]
└── iphone_5_5/
    └── [same 8 screenshots]
```

---

## App Store Connect Upload

1. Go to **App Store Connect** → Your App → App Information

2. Under **Screenshots**, select device size

3. **Drag and drop** screenshots in order

4. Screenshots will be used for:
   - App Store product page
   - Search results
   - Today tab features

---

## Design Tips

- **No device frames needed** - App Store adds them automatically
- **No text overlays** - Add promotional text in App Store Connect instead
- **High contrast** - Make sure text is readable
- **Show real content** - Avoid placeholder/lorem ipsum text
- **Highlight achievements** - Show progress, badges, streaks
- **Clean state** - No error messages or loading states

---

## File Requirements

| Size | Max File Size | Format |
|------|---------------|--------|
| 6.7" | 10 MB | PNG, JPEG |
| 6.5" | 10 MB | PNG, JPEG |
| 5.5" | 10 MB | PNG, JPEG |

Minimum: **2 screenshots** per device size
Maximum: **10 screenshots** per device size
Recommended: **6-8 screenshots**

