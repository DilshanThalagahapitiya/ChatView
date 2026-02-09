import Foundation

/// Defines all possible navigation destinations in the app
enum Destination: Hashable, Identifiable {
    case login
    case signup
    case chatDetail(chat: Chat, currentUser: User)
    
    var id: String {
        switch self {
        case .login:
            return "login"
        case .signup:
            return "signup"
        case .chatDetail(let chat, _):
            return "chatDetail_\(chat.id)"
        }
    }
}

