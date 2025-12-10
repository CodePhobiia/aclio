import SwiftUI

// MARK: - Expanded Content View
struct ExpandedContentView: View {
    let stepTitle: String
    let detailedGuide: String
    let tips: [String]
    let resources: [ExpandResource]
    let isAlreadySaved: Bool
    let onExit: () -> Void
    let onSave: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @State private var isSaved: Bool
    
    init(stepTitle: String, detailedGuide: String, tips: [String], resources: [ExpandResource], isAlreadySaved: Bool, onExit: @escaping () -> Void, onSave: @escaping () -> Void) {
        self.stepTitle = stepTitle
        self.detailedGuide = detailedGuide
        self.tips = tips
        self.resources = resources
        self.isAlreadySaved = isAlreadySaved
        self.onExit = onExit
        self.onSave = onSave
        self._isSaved = State(initialValue: isAlreadySaved)
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        ZStack {
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Button(action: onExit) {
                        Text("Exit")
                            .font(AclioFont.bodyMedium)
                            .foregroundColor(colors.textSecondary)
                    }
                    .frame(width: 60, alignment: .leading)
                    
                    Spacer()
                    
                    Text("Step Details")
                        .font(AclioFont.navTitle)
                        .foregroundColor(colors.textPrimary)
                    
                    Spacer()
                    
                    if !isSaved {
                        Button(action: {
                            AclioHaptics.success()
                            isSaved = true
                            onSave()
                        }) {
                            Text("Save")
                                .font(AclioFont.bodyMedium)
                                .foregroundColor(colors.accent)
                        }
                        .frame(width: 60, alignment: .trailing)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .bold))
                            Text("Saved")
                                .font(AclioFont.captionMedium)
                        }
                        .foregroundColor(colors.success)
                        .frame(width: 60, alignment: .trailing)
                    }
                }
                .padding(.horizontal, AclioSpacing.screenHorizontal)
                .padding(.top, ScreenSize.safeTop + AclioSpacing.space3)
                .padding(.bottom, AclioSpacing.space3)
                .background(colors.headerBackground)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AclioSpacing.space6) {
                        // Step title card
                        VStack(alignment: .leading, spacing: AclioSpacing.space3) {
                            HStack(spacing: AclioSpacing.space3) {
                                ZStack {
                                    Circle()
                                        .fill(colors.accentSoft)
                                        .frame(width: 44, height: 44)
                                    
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 18, weight: .medium))
                                        .foregroundColor(colors.accent)
                                }
                                
                                Text(stepTitle)
                                    .font(AclioFont.title3)
                                    .foregroundColor(colors.textPrimary)
                                    .lineLimit(3)
                            }
                        }
                        .padding(AclioSpacing.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colors.cardBackground)
                        .cornerRadius(AclioRadius.card)
                        .aclioCardShadow(isDark: colorScheme == .dark)
                        
                        // Detailed Guide
                        VStack(alignment: .leading, spacing: AclioSpacing.space4) {
                            HStack(spacing: AclioSpacing.space2) {
                                Image(systemName: "doc.text.fill")
                                    .foregroundColor(colors.accent)
                                Text("Detailed Guide")
                                    .font(AclioFont.sectionTitle)
                                    .foregroundColor(colors.textPrimary)
                            }
                            
                            Text(detailedGuide)
                                .font(AclioFont.body)
                                .foregroundColor(colors.textSecondary)
                                .lineSpacing(6)
                        }
                        .padding(AclioSpacing.cardPadding)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(colors.cardBackground)
                        .cornerRadius(AclioRadius.card)
                        .aclioCardShadow(isDark: colorScheme == .dark)
                        
                        // Tips
                        if !tips.isEmpty {
                            VStack(alignment: .leading, spacing: AclioSpacing.space4) {
                                HStack(spacing: AclioSpacing.space2) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                    Text("Pro Tips")
                                        .font(AclioFont.sectionTitle)
                                        .foregroundColor(colors.textPrimary)
                                }
                                
                                VStack(alignment: .leading, spacing: AclioSpacing.space3) {
                                    ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                                        HStack(alignment: .top, spacing: AclioSpacing.space3) {
                                            Text("💡")
                                                .font(.system(size: 14))
                                            Text(tip)
                                                .font(AclioFont.body)
                                                .foregroundColor(colors.textSecondary)
                                        }
                                    }
                                }
                            }
                            .padding(AclioSpacing.cardPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.yellow.opacity(0.08))
                            .cornerRadius(AclioRadius.card)
                        }
                        
                        // Helpful Links
                        if !resources.isEmpty {
                            VStack(alignment: .leading, spacing: AclioSpacing.space4) {
                                HStack(spacing: AclioSpacing.space2) {
                                    Image(systemName: "link")
                                        .foregroundColor(colors.accent)
                                    Text("Helpful Links")
                                        .font(AclioFont.sectionTitle)
                                        .foregroundColor(colors.textPrimary)
                                }
                                
                                VStack(spacing: AclioSpacing.space3) {
                                    ForEach(Array(resources.enumerated()), id: \.offset) { index, resource in
                                        Button(action: {
                                            if let urlString = resource.url, let url = URL(string: urlString) {
                                                openURL(url)
                                            }
                                        }) {
                                            HStack(spacing: AclioSpacing.space3) {
                                                ZStack {
                                                    Circle()
                                                        .fill(colors.accentSoft)
                                                        .frame(width: 36, height: 36)
                                                    
                                                    Image(systemName: resourceIcon(for: resource.type))
                                                        .font(.system(size: 14, weight: .medium))
                                                        .foregroundColor(colors.accent)
                                                }
                                                
                                                VStack(alignment: .leading, spacing: 2) {
                                                    Text(resource.name)
                                                        .font(AclioFont.bodyMedium)
                                                        .foregroundColor(colors.textPrimary)
                                                        .lineLimit(1)
                                                    
                                                    HStack(spacing: AclioSpacing.space2) {
                                                        if let type = resource.type {
                                                            Text(type.capitalized)
                                                                .font(AclioFont.caption)
                                                                .foregroundColor(colors.textMuted)
                                                        }
                                                        if let cost = resource.cost {
                                                            Text("• \(cost)")
                                                                .font(AclioFont.caption)
                                                                .foregroundColor(cost.lowercased() == "free" ? colors.success : colors.textMuted)
                                                        }
                                                    }
                                                }
                                                
                                                Spacer()
                                                
                                                if resource.url != nil {
                                                    Image(systemName: "arrow.up.right")
                                                        .font(.system(size: 12, weight: .medium))
                                                        .foregroundColor(colors.textMuted)
                                                }
                                            }
                                            .padding(AclioSpacing.space3)
                                            .background(colors.cardBackground)
                                            .cornerRadius(AclioRadius.medium)
                                        }
                                        .disabled(resource.url == nil)
                                    }
                                }
                            }
                            .padding(AclioSpacing.cardPadding)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(colors.accentSoft.opacity(0.5))
                            .cornerRadius(AclioRadius.card)
                        }
                    }
                    .padding(.horizontal, AclioSpacing.screenHorizontal)
                    .padding(.vertical, AclioSpacing.space6)
                    .padding(.bottom, AclioSpacing.space8)
                }
            }
        }
        .navigationBarHidden(true)
    }
    
    private func resourceIcon(for type: String?) -> String {
        switch type?.lowercased() {
        case "video": return "play.circle.fill"
        case "article": return "doc.text.fill"
        case "app": return "apps.iphone"
        case "course": return "graduationcap.fill"
        case "book": return "book.fill"
        case "website": return "globe"
        default: return "link"
        }
    }
}

// MARK: - Previews
#Preview("Expanded Content") {
    ExpandedContentView(
        stepTitle: "Research industry trends",
        detailedGuide: """
        Start by identifying the top 5 companies in your target industry. Look at their recent news, product launches, and strategic moves.
        
        Understanding the competitive landscape is crucial for positioning yourself effectively. Take time to analyze their strengths and weaknesses.
        """,
        tips: [
            "Set up Google Alerts for industry keywords",
            "Follow industry leaders on LinkedIn",
            "Subscribe to relevant newsletters"
        ],
        resources: [
            ExpandResource(name: "McKinsey Industry Reports", type: "article", url: "https://mckinsey.com", cost: "Free"),
            ExpandResource(name: "TechCrunch", type: "website", url: "https://techcrunch.com", cost: "Free"),
            ExpandResource(name: "LinkedIn Learning", type: "course", url: "https://linkedin.com/learning", cost: "$29.99/mo")
        ],
        isAlreadySaved: false,
        onExit: {},
        onSave: {}
    )
}


