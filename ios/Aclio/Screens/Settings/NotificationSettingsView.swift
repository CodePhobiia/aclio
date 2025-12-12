import SwiftUI

// MARK: - Notification Settings View
struct NotificationSettingsView: View {
    
    let onBack: () -> Void
    
    @StateObject private var notificationService = NotificationService.shared
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isRequestingPermission = false
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: AclioSpacing.sectionGap) {
                    // Header
                    header
                    
                    // Permission Status
                    if !notificationService.isAuthorized {
                        permissionCard
                    }
                    
                    // Daily Reminder Section
                    dailyReminderSection
                    
                    // Other Notifications Section
                    otherNotificationsSection
                    
                    // Info Section
                    infoSection
                }
                .padding(.horizontal, AclioSpacing.screenHorizontal)
                .padding(.bottom, AclioSpacing.space10)
            }
        }
        .task {
            await notificationService.checkAuthorization()
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            BackButton(action: onBack)
            
            Text("Notifications")
                .font(AclioFont.title2)
                .foregroundColor(colors.textPrimary)
            
            Spacer()
        }
        .padding(.top, ScreenSize.safeTop + AclioSpacing.space3)
    }
    
    // MARK: - Permission Card
    private var permissionCard: some View {
        VStack(spacing: AclioSpacing.space4) {
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 40))
                .foregroundColor(colors.accent)
            
            Text("Enable Notifications")
                .font(AclioFont.title3)
                .foregroundColor(colors.textPrimary)
            
            Text("Get reminders to stay on track with your goals and celebrate your achievements.")
                .font(AclioFont.body)
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            
            Button(action: requestPermission) {
                HStack {
                    if isRequestingPermission {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text("Enable Notifications")
                            .font(AclioFont.buttonMedium)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, AclioSpacing.space4)
                .background(colors.accent)
                .cornerRadius(AclioRadius.button)
            }
            .disabled(isRequestingPermission)
        }
        .padding(AclioSpacing.space6)
        .background(colors.cardBackground)
        .cornerRadius(AclioRadius.card)
    }
    
    // MARK: - Daily Reminder Section
    private var dailyReminderSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            SectionHeader("Daily Reminder")
            
            VStack(spacing: AclioSpacing.space4) {
                Toggle(isOn: $notificationService.dailyReminderEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Daily Reminder")
                            .font(AclioFont.bodyMedium)
                            .foregroundColor(colors.textPrimary)
                        
                        Text("Get a daily reminder to work on your goals")
                            .font(AclioFont.caption)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                .tint(colors.accent)
                .disabled(!notificationService.isAuthorized)
                
                if notificationService.dailyReminderEnabled {
                    Divider()
                    
                    DatePicker(
                        "Reminder Time",
                        selection: $notificationService.dailyReminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(AclioFont.body)
                    .foregroundColor(colors.textPrimary)
                    .disabled(!notificationService.isAuthorized)
                }
            }
            .padding(AclioSpacing.cardPadding)
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.card)
            .opacity(notificationService.isAuthorized ? 1 : 0.5)
        }
    }
    
    // MARK: - Other Notifications Section
    private var otherNotificationsSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            SectionHeader("Notification Types")
            
            VStack(spacing: 0) {
                NotificationTypeRow(
                    icon: "calendar.badge.clock",
                    title: "Goal Due Reminders",
                    description: "Reminders when goals are due soon",
                    isEnabled: true,
                    isDisabled: !notificationService.isAuthorized
                )
                
                Divider()
                    .padding(.leading, 56)
                
                NotificationTypeRow(
                    icon: "flame.fill",
                    title: "Streak Reminders",
                    description: "Keep your streak alive",
                    isEnabled: true,
                    isDisabled: !notificationService.isAuthorized
                )
                
                Divider()
                    .padding(.leading, 56)
                
                NotificationTypeRow(
                    icon: "trophy.fill",
                    title: "Achievements",
                    description: "Celebrate when you unlock achievements",
                    isEnabled: true,
                    isDisabled: !notificationService.isAuthorized
                )
                
                Divider()
                    .padding(.leading, 56)
                
                NotificationTypeRow(
                    icon: "sparkles",
                    title: "Motivational",
                    description: "Inspirational messages to keep you going",
                    isEnabled: true,
                    isDisabled: !notificationService.isAuthorized
                )
            }
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.card)
            .opacity(notificationService.isAuthorized ? 1 : 0.5)
        }
    }
    
    // MARK: - Info Section
    private var infoSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            HStack(spacing: AclioSpacing.space3) {
                Image(systemName: "info.circle")
                    .font(.system(size: 16))
                    .foregroundColor(colors.textMuted)
                
                Text("You can always change notification settings in your device's Settings app.")
                    .font(AclioFont.caption)
                    .foregroundColor(colors.textMuted)
            }
            
            if notificationService.authorizationStatus == .denied {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                .font(AclioFont.caption)
                .foregroundColor(colors.accent)
            }
        }
        .padding(.horizontal, AclioSpacing.space2)
    }
    
    // MARK: - Actions
    
    private func requestPermission() {
        isRequestingPermission = true
        Task {
            let granted = await notificationService.requestAuthorization()
            isRequestingPermission = false
            
            if granted {
                // Track analytics
                AnalyticsService.shared.track(AnalyticsEventName.notificationsToggled, parameters: [
                    "enabled": "true"
                ])
            }
        }
    }
}

// MARK: - Notification Type Row
struct NotificationTypeRow: View {
    let icon: String
    let title: String
    let description: String
    let isEnabled: Bool
    let isDisabled: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        HStack(spacing: AclioSpacing.space3) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(isDisabled ? colors.textMuted : colors.accent)
                .frame(width: 40)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AclioFont.bodyMedium)
                    .foregroundColor(isDisabled ? colors.textMuted : colors.textPrimary)
                
                Text(description)
                    .font(AclioFont.caption)
                    .foregroundColor(colors.textSecondary)
            }
            
            Spacer()
            
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(isEnabled && !isDisabled ? colors.success : colors.textMuted)
        }
        .padding(.horizontal, AclioSpacing.space4)
        .padding(.vertical, AclioSpacing.space3)
    }
}

// MARK: - Preview
#Preview {
    NotificationSettingsView(onBack: {})
}

