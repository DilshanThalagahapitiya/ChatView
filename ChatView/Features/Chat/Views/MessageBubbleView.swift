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
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if !isCurrentUser {
                // Avatar for incoming messages
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: ChatConstants.UI.avatarSize, height: ChatConstants.UI.avatarSize)
                    .overlay(Text(message.senderId.prefix(1)).font(.caption))
            } else {
                Spacer()
            }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                switch message.content {
                case .text(let text):
                    Text(text)
                        .padding(ChatConstants.UI.messagePadding)
                        .background(isCurrentUser ? ChatConstants.Colors.outgoingBubble : ChatConstants.Colors.incomingBubble)
                        .foregroundColor(isCurrentUser ? ChatConstants.Colors.outgoingText : ChatConstants.Colors.incomingText)
                        .cornerRadius(ChatConstants.UI.bubbleCornerRadius)
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
                    }
                    .frame(maxWidth: 250, maxHeight: 300)
                    .cornerRadius(12)
                }
                
                Text(message.timestamp.formatted(.dateTime.hour().minute()))
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            if isCurrentUser {
                // Status indicator
                statusIcon
            } else {
                Spacer()
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
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
        }
        .font(.caption2)
        .foregroundColor(.gray)
    }
}
