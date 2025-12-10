import SwiftUI

// MARK: - Chip View
struct ChipView: View {
    let text: String
    let isSelected: Bool
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    init(_ text: String, isSelected: Bool = false, onTap: @escaping () -> Void) {
        self.text = text
        self.isSelected = isSelected
        self.onTap = onTap
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        Button(action: {
            AclioHaptics.light()
            onTap()
        }) {
            Text(text)
                .font(AclioFont.pill)
                .foregroundColor(isSelected ? .white : colors.textSecondary)
                .padding(.horizontal, AclioSpacing.chipPaddingH)
                .padding(.vertical, AclioSpacing.chipPaddingV)
                .background(isSelected ? colors.accent : colors.pillBackground)
                .cornerRadius(AclioRadius.chip)
        }
    }
}

// MARK: - Chip Group
struct ChipGroup: View {
    let chips: [String]
    let onSelect: (String) -> Void
    
    var body: some View {
        FlowLayout(spacing: AclioSpacing.space2) {
            ForEach(chips, id: \.self) { chip in
                ChipView(chip) {
                    onSelect(chip)
                }
            }
        }
    }
}

// MARK: - Flow Layout (for wrapping chips)
struct FlowLayout: Layout {
    let spacing: CGFloat
    
    init(spacing: CGFloat = 8) {
        self.spacing = spacing
    }
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }
                
                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
                
                self.size.width = max(self.size.width, x - spacing)
            }
            
            self.size.height = y + rowHeight
        }
    }
}

// MARK: - Quick Prompt Chip
struct QuickPromptChip: View {
    let text: String
    let onTap: () -> Void
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        Button(action: {
            AclioHaptics.light()
            onTap()
        }) {
            Text(text)
                .font(AclioFont.body)
                .foregroundColor(colors.textPrimary)
                .padding(.horizontal, AclioSpacing.space4)
                .padding(.vertical, AclioSpacing.space3)
                .background(colors.cardBackground)
                .cornerRadius(AclioRadius.pill)
                .overlay(
                    RoundedRectangle(cornerRadius: AclioRadius.pill)
                        .stroke(colors.border, lineWidth: 1)
                )
        }
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 24) {
        HStack {
            ChipView("Learn a language", isSelected: false) {}
            ChipView("Run a marathon", isSelected: true) {}
        }
        
        ChipGroup(chips: ["Swift", "SwiftUI", "iOS", "macOS", "watchOS"]) { chip in
            print("Selected: \(chip)")
        }
        
        HStack {
            QuickPromptChip(text: "Give me motivation") {}
            QuickPromptChip(text: "Tips for this step") {}
        }
    }
    .padding()
    .background(Color.aclioPageBg)
}


