import SwiftUI

// MARK: - Safe Area Insets Environment

private struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        EdgeInsets()
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        get { self[SafeAreaInsetsKey.self] }
        set { self[SafeAreaInsetsKey.self] = newValue }
    }
}

// MARK: - Safe Area Reader

struct SafeAreaReader<Content: View>: View {
    let content: (EdgeInsets) -> Content
    
    init(@ViewBuilder content: @escaping (EdgeInsets) -> Content) {
        self.content = content
    }
    
    var body: some View {
        GeometryReader { geometry in
            content(geometry.safeAreaInsets)
        }
    }
}

// MARK: - Safe Area Insets Provider

struct SafeAreaInsetsProvider: ViewModifier {
    @State private var insets: EdgeInsets = EdgeInsets()
    
    func body(content: Content) -> some View {
        content
            .environment(\.safeAreaInsets, insets)
            .background(
                GeometryReader { geometry in
                    Color.clear
                        .onAppear {
                            insets = geometry.safeAreaInsets
                        }
                        .onChange(of: geometry.safeAreaInsets) { _, newValue in
                            insets = newValue
                        }
                }
            )
    }
}

extension View {
    func provideSafeAreaInsets() -> some View {
        modifier(SafeAreaInsetsProvider())
    }
}

// MARK: - Keyboard Height Observer

final class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var isKeyboardVisible: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            }
            .sink { [weak self] height in
                withAnimation(.easeOut(duration: 0.25)) {
                    self?.keyboardHeight = height
                    self?.isKeyboardVisible = true
                }
            }
            .store(in: &cancellables)
        
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in
                withAnimation(.easeOut(duration: 0.25)) {
                    self?.keyboardHeight = 0
                    self?.isKeyboardVisible = false
                }
            }
            .store(in: &cancellables)
    }
}

import Combine

// MARK: - Keyboard Aware Modifier

struct KeyboardAwareModifier: ViewModifier {
    @StateObject private var keyboardObserver = KeyboardObserver()
    let offset: Bool
    
    func body(content: Content) -> some View {
        content
            .padding(.bottom, offset ? keyboardObserver.keyboardHeight : 0)
            .ignoresSafeArea(.keyboard)
    }
}

extension View {
    func keyboardAware(offset: Bool = true) -> some View {
        modifier(KeyboardAwareModifier(offset: offset))
    }
}

// MARK: - Screen Size Helper

struct ScreenSize {
    static var width: CGFloat {
        UIScreen.main.bounds.width
    }
    
    static var height: CGFloat {
        UIScreen.main.bounds.height
    }
    
    static var isSmallDevice: Bool {
        height < 700 // iPhone SE, 8
    }
    
    static var isMediumDevice: Bool {
        height >= 700 && height < 850
    }
    
    static var isLargeDevice: Bool {
        height >= 850
    }
    
    static var hasNotch: Bool {
        UIApplication.shared.safeAreaInsets.top > 20
    }
    
    static var safeTop: CGFloat {
        UIApplication.shared.safeAreaInsets.top
    }
    
    static var safeBottom: CGFloat {
        UIApplication.shared.safeAreaInsets.bottom
    }
}

// MARK: - Adaptive Layout Values

struct AdaptiveLayout {
    
    static var headerPadding: CGFloat {
        ScreenSize.hasNotch ? 16 : 12
    }
    
    static var mascotSize: CGFloat {
        if ScreenSize.isSmallDevice {
            return 100
        } else if ScreenSize.isMediumDevice {
            return 140
        } else {
            return 180
        }
    }
    
    static var welcomeMascotSize: CGFloat {
        if ScreenSize.isSmallDevice {
            return 140
        } else if ScreenSize.isMediumDevice {
            return 180
        } else {
            return 220
        }
    }
    
    static var onboardingImageSize: CGFloat {
        if ScreenSize.isSmallDevice {
            return 100
        } else if ScreenSize.isMediumDevice {
            return 140
        } else {
            return 180
        }
    }
}

