import SwiftUI

// MARK: - Developer Settings View
struct DeveloperSettingsView: View {
    
    let onBack: () -> Void
    
    @StateObject private var featureFlags = FeatureFlagService.shared
    @StateObject private var analytics = AnalyticsService.shared
    @StateObject private var crashReporting = CrashReportingService.shared
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showExportSheet = false
    @State private var exportData: String = ""
    @State private var showClearConfirm = false
    
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
                    
                    // Feature Flags Section
                    featureFlagsSection
                    
                    // Analytics Section
                    analyticsSection
                    
                    // Crash Reporting Section
                    crashReportingSection
                    
                    // Debug Actions
                    debugActionsSection
                    
                    // App Info
                    appInfoSection
                }
                .padding(.horizontal, AclioSpacing.screenHorizontal)
                .padding(.bottom, AclioSpacing.space10)
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportDataSheet(data: exportData)
        }
        .confirmationDialog("Clear All Debug Data?", isPresented: $showClearConfirm, titleVisibility: .visible) {
            Button("Clear Analytics", role: .destructive) {
                analytics.clearEvents()
            }
            Button("Clear Crash Data", role: .destructive) {
                crashReporting.clearAllData()
            }
            Button("Clear All", role: .destructive) {
                analytics.clearEvents()
                crashReporting.clearAllData()
                featureFlags.clearAllOverrides()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
    
    // MARK: - Header
    private var header: some View {
        HStack {
            BackButton(action: onBack)
            
            Text("Developer Settings")
                .font(AclioFont.title2)
                .foregroundColor(colors.textPrimary)
            
            Spacer()
        }
        .padding(.top, ScreenSize.safeTop + AclioSpacing.space3)
    }
    
    // MARK: - Feature Flags Section
    private var featureFlagsSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            SectionHeader("Feature Flags")
            
            VStack(spacing: 0) {
                ForEach(FeatureFlag.FlagCategory.allCases, id: \.rawValue) { category in
                    let flags = FeatureFlag.allCases.filter { $0.category == category }
                    
                    if !flags.isEmpty {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(category.rawValue)
                                .font(AclioFont.captionMedium)
                                .foregroundColor(colors.textMuted)
                                .padding(.horizontal, AclioSpacing.space4)
                                .padding(.vertical, AclioSpacing.space2)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(colors.pillBackground)
                            
                            ForEach(flags, id: \.rawValue) { flag in
                                FeatureFlagRow(flag: flag, featureFlags: featureFlags)
                            }
                        }
                    }
                }
            }
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.card)
            
            Button("Reset All Overrides") {
                featureFlags.clearAllOverrides()
            }
            .font(AclioFont.caption)
            .foregroundColor(colors.destructive)
        }
    }
    
    // MARK: - Analytics Section
    private var analyticsSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            SectionHeader("Analytics")
            
            VStack(spacing: AclioSpacing.space3) {
                HStack {
                    Text("Events Tracked")
                        .font(AclioFont.body)
                        .foregroundColor(colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(analytics.allEvents.count)")
                        .font(AclioFont.bodyMedium)
                        .foregroundColor(colors.accent)
                }
                
                Toggle("Analytics Enabled", isOn: Binding(
                    get: { analytics.isEnabled },
                    set: { analytics.setEnabled($0) }
                ))
                .font(AclioFont.body)
                .tint(colors.accent)
                
                Button("Export Analytics") {
                    if let data = analytics.exportEvents(),
                       let string = String(data: data, encoding: .utf8) {
                        exportData = string
                        showExportSheet = true
                    }
                }
                .font(AclioFont.body)
                .foregroundColor(colors.accent)
            }
            .padding(AclioSpacing.cardPadding)
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.card)
        }
    }
    
    // MARK: - Crash Reporting Section
    private var crashReportingSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            SectionHeader("Crash Reporting")
            
            VStack(spacing: AclioSpacing.space3) {
                HStack {
                    Text("Crash Reports")
                        .font(AclioFont.body)
                        .foregroundColor(colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(crashReporting.crashReports.count)")
                        .font(AclioFont.bodyMedium)
                        .foregroundColor(crashReporting.crashReports.isEmpty ? colors.textMuted : colors.destructive)
                }
                
                HStack {
                    Text("Error Logs")
                        .font(AclioFont.body)
                        .foregroundColor(colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(crashReporting.errorLogs.count)")
                        .font(AclioFont.bodyMedium)
                        .foregroundColor(colors.accent)
                }
                
                HStack {
                    Text("Breadcrumbs")
                        .font(AclioFont.body)
                        .foregroundColor(colors.textPrimary)
                    
                    Spacer()
                    
                    Text("\(crashReporting.breadcrumbs.count)")
                        .font(AclioFont.bodyMedium)
                        .foregroundColor(colors.textMuted)
                }
                
                Button("Export Crash Data") {
                    if let data = crashReporting.exportCrashData(),
                       let string = String(data: data, encoding: .utf8) {
                        exportData = string
                        showExportSheet = true
                    }
                }
                .font(AclioFont.body)
                .foregroundColor(colors.accent)
                
                Button("Test Error Log") {
                    crashReporting.logError("Test error from developer settings", context: ["source": "dev_settings"])
                }
                .font(AclioFont.body)
                .foregroundColor(colors.teal)
            }
            .padding(AclioSpacing.cardPadding)
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.card)
        }
    }
    
    // MARK: - Debug Actions
    private var debugActionsSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            SectionHeader("Debug Actions")
            
            VStack(spacing: AclioSpacing.space3) {
                Button("Test Deep Link: New Goal") {
                    DeepLinkService.shared.navigate(to: .newGoal)
                }
                .font(AclioFont.body)
                .foregroundColor(colors.accent)
                
                Button("Test Deep Link: Chat") {
                    DeepLinkService.shared.navigate(to: .chat(goalId: nil))
                }
                .font(AclioFont.body)
                .foregroundColor(colors.accent)
                
                Button("Test Notification") {
                    Task {
                        await NotificationService.shared.requestAuthorization()
                        NotificationService.shared.sendAchievementNotification(achievementName: "Test Achievement")
                    }
                }
                .font(AclioFont.body)
                .foregroundColor(colors.teal)
                
                Divider()
                
                Button("Clear All Debug Data") {
                    showClearConfirm = true
                }
                .font(AclioFont.body)
                .foregroundColor(colors.destructive)
            }
            .padding(AclioSpacing.cardPadding)
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.card)
        }
    }
    
    // MARK: - App Info
    private var appInfoSection: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
            SectionHeader("App Info")
            
            VStack(spacing: AclioSpacing.space2) {
                InfoRow(label: "Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                InfoRow(label: "Build", value: Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown")
                InfoRow(label: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "Unknown")
                InfoRow(label: "iOS Version", value: UIDevice.current.systemVersion)
                InfoRow(label: "Device", value: UIDevice.current.model)
            }
            .padding(AclioSpacing.cardPadding)
            .background(colors.cardBackground)
            .cornerRadius(AclioRadius.card)
        }
    }
}

// MARK: - Feature Flag Row
struct FeatureFlagRow: View {
    let flag: FeatureFlag
    @ObservedObject var featureFlags: FeatureFlagService
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(flag.displayName)
                    .font(AclioFont.body)
                    .foregroundColor(colors.textPrimary)
                
                if featureFlags.hasOverride(flag) {
                    Text("Overridden")
                        .font(AclioFont.caption)
                        .foregroundColor(colors.accent)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { featureFlags.isEnabled(flag) },
                set: { featureFlags.setOverride(flag, enabled: $0) }
            ))
            .tint(colors.accent)
        }
        .padding(.horizontal, AclioSpacing.space4)
        .padding(.vertical, AclioSpacing.space3)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(AclioFont.body)
                .foregroundColor(colors.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(AclioFont.bodyMedium)
                .foregroundColor(colors.textPrimary)
        }
    }
}

// MARK: - Export Data Sheet
struct ExportDataSheet: View {
    let data: String
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                Text(data)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(colors.textPrimary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(colors.background)
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Copy") {
                        UIPasteboard.general.string = data
                    }
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    DeveloperSettingsView(onBack: {})
}

