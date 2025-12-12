import Foundation
import SwiftUI

// MARK: - App Error Types
enum AppError: LocalizedError, Identifiable {
    case networkError
    case serverError(String)
    case validationError(String)
    case timeout
    case rateLimited
    case unauthorized
    case unknown(Error?)
    
    var id: String {
        switch self {
        case .networkError: return "network"
        case .serverError(let msg): return "server_\(msg.hashValue)"
        case .validationError(let msg): return "validation_\(msg.hashValue)"
        case .timeout: return "timeout"
        case .rateLimited: return "rate_limited"
        case .unauthorized: return "unauthorized"
        case .unknown: return "unknown"
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .networkError:
            return "Unable to connect to the server. Please check your internet connection and try again."
        case .serverError(let message):
            return message
        case .validationError(let message):
            return message
        case .timeout:
            return "The request took too long. Please try again."
        case .rateLimited:
            return "You're making too many requests. Please wait a moment and try again."
        case .unauthorized:
            return "Your session has expired. Please restart the app."
        case .unknown(let error):
            return error?.localizedDescription ?? "Something went wrong. Please try again."
        }
    }
    
    var title: String {
        switch self {
        case .networkError:
            return "Connection Error"
        case .serverError:
            return "Server Error"
        case .validationError:
            return "Invalid Input"
        case .timeout:
            return "Request Timeout"
        case .rateLimited:
            return "Slow Down"
        case .unauthorized:
            return "Session Expired"
        case .unknown:
            return "Error"
        }
    }
    
    var icon: String {
        switch self {
        case .networkError:
            return "wifi.slash"
        case .serverError:
            return "exclamationmark.icloud"
        case .validationError:
            return "exclamationmark.triangle"
        case .timeout:
            return "clock.badge.exclamationmark"
        case .rateLimited:
            return "tortoise"
        case .unauthorized:
            return "lock.slash"
        case .unknown:
            return "questionmark.circle"
        }
    }
    
    var isRetryable: Bool {
        switch self {
        case .networkError, .timeout, .rateLimited, .serverError:
            return true
        case .validationError, .unauthorized, .unknown:
            return false
        }
    }
    
    // MARK: - Factory Methods
    
    static func from(_ error: Error) -> AppError {
        if let apiError = error as? ApiError {
            return from(apiError)
        }
        
        let nsError = error as NSError
        
        // Check for network-related errors
        if nsError.domain == NSURLErrorDomain {
            switch nsError.code {
            case NSURLErrorNotConnectedToInternet,
                 NSURLErrorNetworkConnectionLost,
                 NSURLErrorCannotFindHost,
                 NSURLErrorCannotConnectToHost:
                return .networkError
            case NSURLErrorTimedOut:
                return .timeout
            default:
                return .serverError(error.localizedDescription)
            }
        }
        
        return .unknown(error)
    }
    
    static func from(_ apiError: ApiError) -> AppError {
        switch apiError {
        case .invalidURL:
            return .serverError("Invalid request URL")
        case .noData:
            return .serverError("No response from server")
        case .decodingError:
            return .serverError("Unable to process server response")
        case .serverError(let message):
            if message.lowercased().contains("too many requests") ||
               message.lowercased().contains("rate limit") {
                return .rateLimited
            }
            return .serverError(message)
        case .networkError(let error):
            return .from(error)
        }
    }
}

// MARK: - Error Alert View Modifier
struct ErrorAlertModifier: ViewModifier {
    @Binding var error: AppError?
    var onRetry: (() -> Void)?
    
    func body(content: Content) -> some View {
        content
            .alert(
                error?.title ?? "Error",
                isPresented: Binding(
                    get: { error != nil },
                    set: { if !$0 { error = nil } }
                ),
                presenting: error
            ) { presentedError in
                if presentedError.isRetryable, let retry = onRetry {
                    Button("Retry") {
                        error = nil
                        retry()
                    }
                    Button("Dismiss", role: .cancel) {
                        error = nil
                    }
                } else {
                    Button("OK", role: .cancel) {
                        error = nil
                    }
                }
            } message: { presentedError in
                Text(presentedError.errorDescription ?? "Unknown error")
            }
    }
}

// MARK: - View Extension
extension View {
    func errorAlert(_ error: Binding<AppError?>, onRetry: (() -> Void)? = nil) -> some View {
        modifier(ErrorAlertModifier(error: error, onRetry: onRetry))
    }
}

// MARK: - Error Banner View (for inline errors)
struct ErrorBanner: View {
    let error: AppError
    let onDismiss: () -> Void
    var onRetry: (() -> Void)?
    
    @Environment(\.colorScheme) private var colorScheme
    
    private var colors: AclioColors {
        AclioColors(colorScheme)
    }
    
    var body: some View {
        HStack(spacing: AclioSpacing.space3) {
            Image(systemName: error.icon)
                .font(.system(size: 20))
                .foregroundColor(.white)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(error.title)
                    .font(AclioFont.bodyBold)
                    .foregroundColor(.white)
                
                Text(error.errorDescription ?? "")
                    .font(AclioFont.caption)
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
            }
            
            Spacer()
            
            if error.isRetryable, let retry = onRetry {
                Button(action: retry) {
                    Text("Retry")
                        .font(AclioFont.caption)
                        .foregroundColor(.white)
                        .padding(.horizontal, AclioSpacing.space3)
                        .padding(.vertical, AclioSpacing.space2)
                        .background(Color.white.opacity(0.2))
                        .cornerRadius(AclioRadius.small)
                }
            }
            
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
        .padding(AclioSpacing.space4)
        .background(Color.red.opacity(0.9))
        .cornerRadius(AclioRadius.large)
        .padding(.horizontal, AclioSpacing.screenHorizontal)
    }
}

// MARK: - Toast-style Error View
struct ErrorToast: View {
    let message: String
    
    var body: some View {
        HStack(spacing: AclioSpacing.space2) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.orange)
            
            Text(message)
                .font(AclioFont.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, AclioSpacing.space4)
        .padding(.vertical, AclioSpacing.space3)
        .background(Color.black.opacity(0.8))
        .cornerRadius(AclioRadius.full)
    }
}

