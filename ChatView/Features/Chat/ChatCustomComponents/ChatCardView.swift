//
//  ChatCardView.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-09.
//

import SwiftUI

struct ChatCardView: View {
    let chat: Chat
    @EnvironmentObject var authVM: AuthVM
    
    // MARK: - Computed Properties
    private var otherParticipant: User? {
        guard let currentUserID = authVM.currentUser?.id else { return nil }
        return chat.participants.first(where: { $0.id != currentUserID })
    }
    
    private var displayName: String {
        chat.isGroup ? (chat.groupName ?? "Group") : (otherParticipant?.name ?? "Unknown")
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // 1. Avatar Section
            avatarView
            
            // 2. Info Section
            VStack(alignment: .leading, spacing: 6) {
                // Name and Time
                HStack {
                    Text(displayName)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let lastMsg = chat.lastMessage {
                        Text(lastMsg.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } //: HStack (Top Row)
                
                // Message Preview and Badge
                HStack(alignment: .center) {
                    messagePreviewText
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor) // Matches system theme
                            .clipShape(Capsule())
                    }
                } //: HStack (Bottom Row)
            } //: VStack
        } //: HStack
        .padding(.vertical, 8)
        .contentShape(Rectangle()) // Makes the whole row tappable
    } //: body
    
    // MARK: - Subviews
    private var avatarView: some View {
        ZStack {
            let avatarURL = chat.isGroup ? chat.groupIconURL : otherParticipant?.avatarURL
            
            if let url = avatarURL {
                AsyncImage(url: url) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    placeholderCircle
                }
            } else {
                placeholderCircle
            }
        } //: ZStack
        .frame(width: 56, height: 56)
        .clipShape(Circle())
    }
    
    private var placeholderCircle: some View {
        Circle()
            .fill(Color.accentColor.opacity(0.15))
            .overlay(
                Text(chat.isGroup ? "G" : (otherParticipant?.name.prefix(1) ?? "?"))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.accentColor)
            )
    }
    
    @ViewBuilder
    private var messagePreviewText: some View {
        if let lastMsg = chat.lastMessage {
            switch lastMsg.content {
            case .text(let text):
                Text(text)
            case .image:
                Label("Photo", systemImage: "camera.fill")
            case .video:
                Label("Video", systemImage: "video.fill")
            }
        } else {
            Text("No messages yet").italic()
        }
    }
}

// MARK: - Preview
#Preview {
    ChatCardView(chat: .previewChat)
        .environmentObject(AuthVM())
        .padding()
}
