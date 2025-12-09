import SwiftUI

// MARK: - Section Header
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let action: (() -> Void)?
    let actionLabel: String?
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        _ title: String,
        subtitle: String? = nil,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionLabel = actionLabel
        self.action = action
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AclioFont.sectionTitle)
                    .foregroundColor(colors.textPrimary)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AclioFont.caption)
                        .foregroundColor(colors.textSecondary)
                }
            }
            
            Spacer()
            
            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(AclioFont.captionMedium)
                        .foregroundColor(colors.accent)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        SectionHeader("Active Goals")
        
        SectionHeader("Achievements", subtitle: "3 of 12 unlocked")
        
        SectionHeader("Recent Activity", actionLabel: "See All") {
            print("Tapped")
        }
    }
    .padding()
}

