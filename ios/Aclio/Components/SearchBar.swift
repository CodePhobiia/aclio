import SwiftUI

// MARK: - Search Bar
struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    
    init(text: Binding<String>, placeholder: String = "Search...") {
        self._text = text
        self.placeholder = placeholder
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        HStack(spacing: AclioSpacing.space3) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(colors.textMuted)
            
            TextField(placeholder, text: $text)
                .font(AclioFont.body)
                .foregroundColor(colors.textPrimary)
                .focused($isFocused)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                    AclioHaptics.light()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(colors.textMuted)
                }
            }
        }
        .padding(.horizontal, AclioSpacing.space4)
        .padding(.vertical, AclioSpacing.space3)
        .background(colors.inputBackground)
        .cornerRadius(AclioRadius.input)
        .overlay(
            RoundedRectangle(cornerRadius: AclioRadius.input)
                .stroke(isFocused ? colors.accent : .clear, lineWidth: 1.5)
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        SearchBar(text: .constant(""), placeholder: "Search goals...")
        SearchBar(text: .constant("Learn Swift"))
    }
    .padding()
    .background(Color.aclioPageBg)
}


