import SwiftUI

// MARK: - Profile Setup View
struct ProfileSetupView: View {
    @Binding var profile: UserProfile
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    @State private var localName: String = ""
    @State private var localAge: String = ""
    @State private var localGender: Gender?
    
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, age
    }
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    private var canContinue: Bool {
        !localName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        ZStack {
            // Background
            colors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button
                HStack {
                    Spacer()
                    
                    Button(action: {
                        AclioHaptics.light()
                        onSkip()
                    }) {
                        Text("Skip")
                            .font(AclioFont.bodyMedium)
                            .foregroundColor(colors.textSecondary)
                    }
                }
                .padding(.horizontal, AclioSpacing.screenHorizontal)
                .padding(.top, ScreenSize.safeTop + AclioSpacing.space3)
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: AclioSpacing.space8) {
                        // Header
                        VStack(spacing: AclioSpacing.space2) {
                            Text("Tell us about yourself")
                                .font(AclioFont.title2)
                                .foregroundColor(colors.textPrimary)
                            
                            Text("This helps us personalize your experience")
                                .font(AclioFont.body)
                                .foregroundColor(colors.textSecondary)
                        }
                        .multilineTextAlignment(.center)
                        .padding(.top, AclioSpacing.space6)
                        
                        // Form
                        VStack(spacing: AclioSpacing.space5) {
                            // Name field
                            VStack(alignment: .leading, spacing: AclioSpacing.space2) {
                                Text("Your Name *")
                                    .font(AclioFont.inputLabel)
                                    .foregroundColor(colors.textSecondary)
                                
                                TextField("e.g., Theyab", text: $localName)
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
                                    .autocorrectionDisabled()
                            }
                            
                            // Age field
                            VStack(alignment: .leading, spacing: AclioSpacing.space2) {
                                Text("Your Age")
                                    .font(AclioFont.inputLabel)
                                    .foregroundColor(colors.textSecondary)
                                
                                TextField("e.g., 22", text: $localAge)
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
                            
                            // Gender selection
                            VStack(alignment: .leading, spacing: AclioSpacing.space2) {
                                Text("Gender")
                                    .font(AclioFont.inputLabel)
                                    .foregroundColor(colors.textSecondary)
                                
                                HStack(spacing: AclioSpacing.space3) {
                                    ForEach(Gender.allCases, id: \.self) { gender in
                                        Button(action: {
                                            AclioHaptics.selection()
                                            localGender = gender
                                        }) {
                                            Text(gender.displayName)
                                                .font(AclioFont.buttonMedium)
                                                .foregroundColor(localGender == gender ? .white : colors.textPrimary)
                                                .frame(maxWidth: .infinity)
                                                .padding(.vertical, AclioSpacing.space3)
                                                .background(localGender == gender ? colors.accent : colors.inputBackground)
                                                .cornerRadius(AclioRadius.button)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, AclioSpacing.screenHorizontal)
                    }
                }
                
                // Continue button
                VStack {
                    PrimaryButton("Continue", isDisabled: !canContinue) {
                        saveAndContinue()
                    }
                }
                .padding(.horizontal, AclioSpacing.screenHorizontal)
                .padding(.bottom, ScreenSize.safeBottom + AclioSpacing.space6)
            }
        }
        .onAppear {
            localName = profile.name
            localAge = profile.age
            localGender = profile.gender
        }
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private func saveAndContinue() {
        profile = UserProfile(
            name: localName.trimmingCharacters(in: .whitespaces),
            age: localAge,
            gender: localGender
        )
        AclioHaptics.success()
        onComplete()
    }
}

// MARK: - Preview
#Preview {
    ProfileSetupView(
        profile: .constant(UserProfile.empty),
        onComplete: {},
        onSkip: {}
    )
}

