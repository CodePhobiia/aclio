import SwiftUI

// MARK: - Offline Indicator
struct OfflineIndicator: View {
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @State private var isVisible = false
    
    var body: some View {
        Group {
            if !networkMonitor.isConnected {
                offlineBanner
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.3), value: networkMonitor.isConnected)
        .onChange(of: networkMonitor.isConnected) { isConnected in
            if !isConnected {
                // Announce offline status for accessibility
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "You are offline. Some features may be limited."
                )
            } else {
                UIAccessibility.post(
                    notification: .announcement,
                    argument: "Back online"
                )
            }
        }
    }
    
    private var offlineBanner: some View {
        HStack(spacing: AclioSpacing.space2) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 14, weight: .medium))
            
            Text("You're offline")
                .font(AclioFont.captionMedium)
            
            Spacer()
            
            if OfflineQueueService.shared.hasPendingOperations {
                Text("\(OfflineQueueService.shared.pendingCount) pending")
                    .font(AclioFont.caption)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .foregroundColor(.white)
        .padding(.horizontal, AclioSpacing.space4)
        .padding(.vertical, AclioSpacing.space3)
        .background(Color.orange)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Offline mode. \(OfflineQueueService.shared.pendingCount) operations pending sync.")
    }
}

// MARK: - Offline Aware View Modifier
struct OfflineAwareModifier: ViewModifier {
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    
    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            OfflineIndicator()
            content
        }
    }
}

extension View {
    func offlineAware() -> some View {
        modifier(OfflineAwareModifier())
    }
}

// MARK: - Preview
#Preview {
    VStack {
        OfflineIndicator()
        Spacer()
        Text("Content")
        Spacer()
    }
    .environmentObject(NetworkMonitor.shared)
}

