//
//  MessageBubbleView.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-09.
//

import SwiftUI

struct MessageBubbleView: View {
    let message: Message
    let isCurrentUser: Bool
    let senderName: String?
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isCurrentUser {
                // Avatar for incoming messages
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: UIScreen.avatarSize, height: UIScreen.avatarSize)
                    .overlay(Text((senderName ?? message.senderId).prefix(1)).font(.caption))
            } else {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                switch message.content {
                case .text(let text):
                    Text(text)
                        .padding(UIScreen.messagePadding)
                        .background(isCurrentUser ? Color.outgoingBubble : Color.incomingBubble)
                        .foregroundColor(isCurrentUser ? Color.outgoingText : Color.incomingText)
                        .cornerRadius(UIScreen.bubbleCornerRadius)
                        // Add tail logic if desired, for now just simple rounded
                        
                case .image(let media):
                    // Placeholder for image view
                    AsyncImage(url: media.url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                        case .success(let image):
                            image.resizable().scaledToFit()
                        case .failure:
                            Image(systemName: "photo")
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(maxWidth: 250, maxHeight: 300)
                    .cornerRadius(12)
                    
                case .video(let media):
                    // Placeholder for video (thumbnail)
                    ZStack {
                        AsyncImage(url: media.thumbnailURL ?? media.url) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFit()
                            } else {
                                Color.black
                            }
                        }
                        Image(systemName: "play.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                    }//ZStack
                    .frame(maxWidth: 250, maxHeight: 300)
                    .cornerRadius(12)
                }
                
                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }//VStack
            
            if isCurrentUser {
                // Status indicator
                statusIcon
            } else {
                Spacer()
            }
        }//HStack
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    //FIXME: - Need to fix this.
    private var statusIcon: some View {
        Group {
            switch message.status {
            case .sending:
                Image(systemName: "circle")
            case .sent:
                Image(systemName: "checkmark")
            case .delivered:
                Image(systemName: "checkmark.circle")
            case .read:
                Image(systemName: "checkmark.circle.fill")
            case .failed:
                Image(systemName: "exclamationmark.circle.fill").foregroundColor(.red)
            }
        }//Group
        .font(.caption2)
        .foregroundColor(.gray)
    }
}
#Preview {
    VStack(spacing: 20) {
        MessageBubbleView(
            message: Message(senderId: "u1", content: .text("Hello! How are you?"), timestamp: Date(), status: .read),
            isCurrentUser: false,
            senderName: "Alice"
        )
        
        MessageBubbleView(
            message: Message(senderId: "current", content: .text("I'm doing great, thanks for asking!"), timestamp: Date(), status: .sent),
            isCurrentUser: true,
            senderName: "Me"
        )
        
        MessageBubbleView(
            message: Message(senderId: "current", content: .text("Check out this photo!"), timestamp: Date(), status: .delivered),
            isCurrentUser: true,
            senderName: "Me"
        )
        
        MessageBubbleView(
            message: Message(senderId: "u1", content: .image(Media(url: URL(string: "https://picsum.photos/200")!, type: .image)), timestamp: Date(), status: .read),
            isCurrentUser: false,
            senderName: "Alice"
        )
    }
    .padding()
    .previewLayout(.sizeThatFits)
}
