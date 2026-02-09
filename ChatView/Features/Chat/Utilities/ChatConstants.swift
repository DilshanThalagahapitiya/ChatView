import SwiftUI

struct ChatConstants {
    struct UI {
        static let bubbleCornerRadius: CGFloat = 16
        static let avatarSize: CGFloat = 40
        static let messagePadding: CGFloat = 12
        static let standardCreateGroupPadding: CGFloat = 20
        static let inputHeight: CGFloat = 50
    }
    
    struct Colors {
        static let incomingBubble = Color.gray.opacity(0.2)
        static let outgoingBubble = Color.blue
        static let incomingText = Color.primary
        static let outgoingText = Color.white
    }
}
