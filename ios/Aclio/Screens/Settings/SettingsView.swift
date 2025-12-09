import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    
    let onBack: () -> Void
    let onNavigateToEditProfile: () -> Void
    let onNavigateToAnalytics: () -> Void
    let onLogout: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HeaderView(title: "Settings", onBack: onBack)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AclioSpacing.space6) {
                        // Profile Section
                        settingsSection("Profile") {
                            SettingsRow(
                                icon: "person.fill",
                                title: "Edit Profile",
                                value: viewModel.profile.displayName,
                                action: onNavigateToEditProfile
                            )
                        }
                        
                        // Preferences Section
                        settingsSection("Preferences") {
                            SettingsToggleRow(
                                icon: viewModel.isDarkMode ? "moon.fill" : "sun.max.fill",
                                title: "Dark Mode",
                                isOn: $viewModel.isDarkMode,
                                onChange: { _ in viewModel.toggleTheme() }
                            )
                            
                            SettingsToggleRow(
                                icon: "bell.fill",
                                title: "Notifications",
                                isOn: $viewModel.notificationsEnabled,
                                onChange: { _ in viewModel.toggleNotifications() }
                            )
                            
                            SettingsRow(
                                icon: "location.fill",
                                title: "Location",
                                value: viewModel.locationLoading ? "Getting location..." : (viewModel.location?.city ?? "Not set"),
                                showChevron: viewModel.location == nil,
                                action: {
                                    if viewModel.location != nil {
                                        viewModel.clearLocation()
                                    } else {
                                        viewModel.fetchLocation()
                                    }
                                },
                                trailingIcon: viewModel.location != nil ? "xmark" : nil
                            )
                        }
                        
                        // Subscription Section
                        settingsSection("Subscription") {
                            SettingsRow(
                                icon: "crown.fill",
                                iconColor: .aclioGold,
                                title: "Premium Status",
                                value: viewModel.isPremium ? "Active" : "Free Plan",
                                showChevron: !viewModel.isPremium,
                                action: {
                                    if !viewModel.isPremium {
                                        viewModel.showPaywall = true
                                    }
                                }
                            )
                        }
                        
                        // Data Section
                        settingsSection("Data & Privacy") {
                            SettingsRow(
                                icon: "chart.bar.fill",
                                title: "Analytics",
                                action: onNavigateToAnalytics
                            )
                        }
                        
                        // About Section
                        settingsSection("About") {
                            SettingsRow(
                                icon: "info.circle.fill",
                                title: "Version",
                                value: "2.0.0",
                                showChevron: false
                            )
                            
                            SettingsRow(
                                icon: "shield.fill",
                                title: "Privacy Policy",
                                trailingIcon: "arrow.up.forward",
                                action: {
                                    openURL(URL(string: "https://thecribbusiness.github.io/aclio/privacy-policy.html")!)
                                }
                            )
                            
                            SettingsRow(
                                icon: "doc.text.fill",
                                title: "Terms of Service",
                                trailingIcon: "arrow.up.forward",
                                action: {
                                    openURL(URL(string: "https://thecribbusiness.github.io/aclio/terms-of-service.html")!)
                                }
                            )
                        }
                        
                        // Logout
                        Button(action: {
                            viewModel.showLogoutConfirm = true
                        }) {
                            HStack(spacing: AclioSpacing.space2) {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .medium))
                                
                                Text("Sign Out")
                                    .font(AclioFont.buttonMedium)
                            }
                            .foregroundColor(colors.destructive)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, AclioSpacing.space4)
                            .background(colors.destructiveSoft)
                            .cornerRadius(AclioRadius.button)
                        }
                    }
                    .padding(.horizontal, AclioSpacing.screenHorizontal)
                    .padding(.bottom, ScreenSize.safeBottom + AclioSpacing.space8)
                }
            }
        }
        .preferredColorScheme(viewModel.isDarkMode ? .dark : .light)
        .sheet(isPresented: $viewModel.showPaywall) {
            PaywallView(onDismiss: { viewModel.showPaywall = false })
        }
        .confirmationDialog("Sign Out", isPresented: $viewModel.showLogoutConfirm) {
            Button("Sign Out", role: .destructive) {
                viewModel.logout()
                onLogout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out? Your data will be preserved.")
        }
    }
    
    // MARK: - Settings Section
    private func settingsSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            Text(title)
                .font(AclioFont.sectionTitle)
                .foregroundColor(colors.textSecondary)
            
            VStack(spacing: 0) {
                content()
            }
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.card)
            .aclioCardShadow(isDark: colorScheme == .dark)
        }
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    var iconColor: Color?
    let title: String
    var value: String?
    var showChevron: Bool = true
    var action: (() -> Void)?
    var trailingIcon: String?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        Button(action: { action?() }) {
            HStack(spacing: AclioSpacing.space3) {
                ZStack {
                    Circle()
                        .fill((iconColor ?? colors.accent).opacity(0.15))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor ?? colors.accent)
                }
                
                Text(title)
                    .font(AclioFont.body)
                    .foregroundColor(colors.textPrimary)
                
                Spacer()
                
                if let value = value {
                    Text(value)
                        .font(AclioFont.body)
                        .foregroundColor(colors.textSecondary)
                }
                
                if let trailing = trailingIcon {
                    Image(systemName: trailing)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colors.textMuted)
                } else if showChevron && action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(colors.textMuted)
                }
            }
            .padding(AclioSpacing.space4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Settings Toggle Row
struct SettingsToggleRow: View {
    let icon: String
    let title: String
    @Binding var isOn: Bool
    var onChange: ((Bool) -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        HStack(spacing: AclioSpacing.space3) {
            ZStack {
                Circle()
                    .fill(colors.accent.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(colors.accent)
            }
            
            Text(title)
                .font(AclioFont.body)
                .foregroundColor(colors.textPrimary)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(colors.accent)
                .onChange(of: isOn) { _, newValue in
                    onChange?(newValue)
                }
        }
        .padding(AclioSpacing.space4)
    }
}

// MARK: - Preview
#Preview {
    SettingsView(
        onBack: {},
        onNavigateToEditProfile: {},
        onNavigateToAnalytics: {},
        onLogout: {}
    )
}

