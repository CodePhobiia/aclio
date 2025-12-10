import SwiftUI

// MARK: - Header View
struct HeaderView: View {
    let title: String
    let showBack: Bool
    let onBack: (() -> Void)?
    let trailingContent: AnyView?
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        title: String,
        showBack: Bool = true,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: () -> some View = { EmptyView() }
    ) {
        self.title = title
        self.showBack = showBack
        self.onBack = onBack
        self.trailingContent = AnyView(trailing())
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        HStack {
            // Leading
            if showBack {
                BackButton(action: { onBack?() })
            } else {
                Spacer()
                    .frame(width: 40)
            }
            
            Spacer()
            
            // Title
            Text(title)
                .font(AclioFont.navTitle)
                .foregroundColor(colors.textPrimary)
            
            Spacer()
            
            // Trailing
            if let trailing = trailingContent {
                trailing
                    .frame(width: 40, height: 40)
            } else {
                Spacer()
                    .frame(width: 40)
            }
        }
        .padding(.horizontal, AclioSpacing.screenHorizontal)
        .padding(.top, ScreenSize.safeTop + AclioSpacing.space3)
        .padding(.bottom, AclioSpacing.space3)
        .background(colors.background)
    }
}

// MARK: - Hero Header (Dashboard style)
struct HeroHeader: View {
    let greeting: String
    let name: String
    let subtitle: String
    let onNewGoal: () -> Void
    let onThemeToggle: () -> Void
    let onAnalytics: () -> Void
    let onSettings: () -> Void
    let isDarkMode: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: AclioSpacing.space4) {
            // Top icons
            HStack {
                Spacer()
                
                HStack(spacing: AclioSpacing.space2) {
                    IconButton(icon: isDarkMode ? "sun.max.fill" : "moon.fill", style: .hero) {
                        onThemeToggle()
                    }
                    
                    IconButton(icon: "chart.bar.fill", style: .hero) {
                        onAnalytics()
                    }
                    
                    IconButton(icon: "gearshape.fill", style: .hero) {
                        onSettings()
                    }
                }
            }
            .padding(.top, ScreenSize.safeTop + AclioSpacing.space3)
            
            // Greeting
            VStack(alignment: .leading, spacing: AclioSpacing.space1) {
                Text("\(greeting), \(name)!")
                    .font(AclioFont.greeting)
                    .foregroundColor(.aclioHeroText)
                
                Text(subtitle)
                    .font(AclioFont.greetingSubtitle)
                    .foregroundColor(.aclioHeroTextDim)
            }
            
            // CTA Button
            Button(action: onNewGoal) {
                HStack(spacing: AclioSpacing.space2) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                    
                    Text("Create New Goal")
                        .font(AclioFont.buttonMedium)
                }
                .foregroundColor(.aclioHeaderBg)
                .padding(.horizontal, AclioSpacing.space5)
                .padding(.vertical, AclioSpacing.space3)
                .background(Color.white)
                .cornerRadius(AclioRadius.button)
            }
            .padding(.top, AclioSpacing.space2)
        }
        .padding(.horizontal, AclioSpacing.screenHorizontal)
        .padding(.bottom, AclioSpacing.space6)
        .background(Color.aclioHeaderBg)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 0) {
        HeroHeader(
            greeting: "Good morning",
            name: "Theyab",
            subtitle: "Let's make progress on your goals today.",
            onNewGoal: {},
            onThemeToggle: {},
            onAnalytics: {},
            onSettings: {},
            isDarkMode: false
        )
        
        HeaderView(title: "Goal Details", onBack: {})
        
        Spacer()
    }
    .background(Color.aclioPageBg)
    .ignoresSafeArea()
}


