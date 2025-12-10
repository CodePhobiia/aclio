import SwiftUI

// MARK: - Profile Setup View (Screen 4)
struct ProfileSetupView: View {
    @Binding var profile: UserProfile
    let onComplete: () -> Void
    let onSkip: () -> Void
    
    @State private var localName: String = ""
    @State private var localAge: String = ""
    @State private var localGender: Gender?
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, age
    }
    
    // Light blue/gray background color
    private let backgroundColor = Color(hex: "E8EDF5")
    
    private var canContinue: Bool {
        !localName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        ZStack {
            // Light background
            backgroundColor
                .ignoresSafeArea()
            
            // Ambient glow at bottom
            VStack {
                Spacer()
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "FF9F3A").opacity(0.2), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 200)
                    .offset(y: 50)
            }
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
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(hex: "1F2937"))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, ScreenSize.safeTop + 16)
                
                Spacer()
                    .frame(height: 40)
                
                // Header
                VStack(spacing: 12) {
                    Text("Tell us about yourself")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(hex: "0B1C36"))
                    
                    Text("This step is optional — but sharing a bit about yourself helps Aclio personalize your goals and plans just for you.")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(hex: "6B7280"))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 24)
                }
                
                Spacer()
                    .frame(height: 24)
                
                // Progress indicators
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color(hex: "FF9F3A"))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color(hex: "D1D5DB"))
                        .frame(width: 8, height: 8)
                    
                    Circle()
                        .fill(Color(hex: "D1D5DB"))
                        .frame(width: 8, height: 8)
                }
                
                Spacer()
                    .frame(height: 32)
                
                // Form card
                VStack(spacing: 20) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 4) {
                            Text("Your Name")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "374151"))
                            
                            Text("*")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color(hex: "FF9F3A"))
                        }
                        
                        TextField("e.g., Theyab", text: $localName)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "1F2937"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(hex: "F3F4F6"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .name ? Color(hex: "FF9F3A") : Color.clear, lineWidth: 2)
                            )
                            .focused($focusedField, equals: .name)
                            .textInputAutocapitalization(.words)
                            .autocorrectionDisabled()
                    }
                    
                    // Age field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Age")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "374151"))
                        
                        TextField("e.g., 22", text: $localAge)
                            .font(.system(size: 16))
                            .foregroundColor(Color(hex: "1F2937"))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color(hex: "F3F4F6"))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(focusedField == .age ? Color(hex: "FF9F3A") : Color.clear, lineWidth: 2)
                            )
                            .focused($focusedField, equals: .age)
                            .keyboardType(.numberPad)
                    }
                    
                    // Gender selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gender")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "374151"))
                        
                        HStack(spacing: 0) {
                            ForEach(Gender.allCases, id: \.self) { gender in
                                Button(action: {
                                    AclioHaptics.selection()
                                    localGender = gender
                                }) {
                                    Text(gender.displayName)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundColor(localGender == gender ? .white : Color(hex: "1F2937"))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(
                                            localGender == gender 
                                                ? LinearGradient(
                                                    colors: [Color(hex: "FFA63E"), Color(hex: "FF8A3D")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                  )
                                                : LinearGradient(
                                                    colors: [Color(hex: "E5E7EB"), Color(hex: "E5E7EB")],
                                                    startPoint: .leading,
                                                    endPoint: .trailing
                                                  )
                                        )
                                }
                            }
                        }
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color(hex: "E5E7EB"), lineWidth: 1)
                        )
                    }
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.06), radius: 16, x: 0, y: 4)
                .padding(.horizontal, 24)
                
                Spacer()
                    .frame(height: 20)
                
                // Privacy notice
                Text("We never share your details. Aclio only uses this info to personalize your experience.")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(hex: "9CA3AF"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal: 40)
                
                Spacer()
                
                // Continue button
                Button(action: {
                    saveAndContinue()
                }) {
                    Text("Continue")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                colors: canContinue 
                                    ? [Color(hex: "FFA63E"), Color(hex: "FF8A3D"), Color(hex: "FFB85C")]
                                    : [Color(hex: "D1D5DB"), Color(hex: "D1D5DB")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                        .shadow(
                            color: canContinue ? Color(hex: "FF9F3A").opacity(0.3) : Color.clear,
                            radius: 12, x: 0, y: 6
                        )
                }
                .disabled(!canContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, ScreenSize.safeBottom + 24)
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
        .scrollDismissesKeyboard(.interactively)
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
