import SwiftUI

// MARK: - Edit Profile View
struct EditProfileView: View {
    let onBack: () -> Void
    
    @State private var name: String = ""
    @State private var age: String = ""
    @State private var gender: Gender?
    
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: Field?
    
    private let storage = LocalStorageService.shared
    
    enum Field {
        case name, age
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
                HeaderView(title: "Edit Profile", onBack: onBack)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AclioSpacing.space5) {
                        // Name
                        VStack(alignment: .leading, spacing: AclioSpacing.space2) {
                            Text("Your Name")
                                .font(AclioFont.inputLabel)
                                .foregroundColor(colors.textSecondary)
                            
                            TextField("e.g., Theyab", text: $name)
                                .font(AclioFont.input)
                                .foregroundColor(colors.textPrimary)
                                .padding(.horizontal, AclioSpacing.inputPaddingH)
                                .padding(.vertical, AclioSpacing.inputPaddingV)
                                .background(colors.inputBackground)
                                .cornerRadius(AclioRadius.input)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AclioRadius.input)
                                        .stroke(focusedField == .name ? colors.accent : .clear, lineWidth: 1.5)
                                )
                                .focused($focusedField, equals: .name)
                                .textInputAutocapitalization(.words)
                        }
                        
                        // Age
                        VStack(alignment: .leading, spacing: AclioSpacing.space2) {
                            Text("Your Age")
                                .font(AclioFont.inputLabel)
                                .foregroundColor(colors.textSecondary)
                            
                            TextField("e.g., 22", text: $age)
                                .font(AclioFont.input)
                                .foregroundColor(colors.textPrimary)
                                .padding(.horizontal, AclioSpacing.inputPaddingH)
                                .padding(.vertical, AclioSpacing.inputPaddingV)
                                .background(colors.inputBackground)
                                .cornerRadius(AclioRadius.input)
                                .overlay(
                                    RoundedRectangle(cornerRadius: AclioRadius.input)
                                        .stroke(focusedField == .age ? colors.accent : .clear, lineWidth: 1.5)
                                )
                                .focused($focusedField, equals: .age)
                                .keyboardType(.numberPad)
                        }
                        
                        // Gender
                        VStack(alignment: .leading, spacing: AclioSpacing.space2) {
                            Text("Gender")
                                .font(AclioFont.inputLabel)
                                .foregroundColor(colors.textSecondary)
                            
                            HStack(spacing: AclioSpacing.space3) {
                                ForEach(Gender.allCases, id: \.self) { g in
                                    Button(action: {
                                        AclioHaptics.selection()
                                        gender = g
                                    }) {
                                        Text(g.displayName)
                                            .font(AclioFont.buttonMedium)
                                            .foregroundColor(gender == g ? .white : colors.textPrimary)
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, AclioSpacing.space3)
                                            .background(gender == g ? colors.accent : colors.inputBackground)
                                            .cornerRadius(AclioRadius.button)
                                    }
                                }
                            }
                        }
                        
                        // Save Button
                        PrimaryButton("Save Profile") {
                            saveProfile()
                        }
                        .padding(.top, AclioSpacing.space4)
                    }
                    .padding(.horizontal, AclioSpacing.screenHorizontal)
                    .padding(.top, AclioSpacing.space6)
                    .padding(.bottom, ScreenSize.safeBottom + AclioSpacing.space8)
                }
            }
        }
        .onAppear {
            loadProfile()
        }
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private func loadProfile() {
        if let profile = storage.loadProfile() {
            name = profile.name
            age = profile.age
            gender = profile.gender
        }
    }
    
    private func saveProfile() {
        let profile = UserProfile(
            name: name.trimmingCharacters(in: .whitespaces),
            age: age,
            gender: gender
        )
        storage.saveProfile(profile)
        AclioHaptics.success()
        onBack()
    }
}

// MARK: - Preview
#Preview {
    EditProfileView(onBack: {})
}

