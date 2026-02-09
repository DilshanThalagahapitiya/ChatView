//
//  ChatCardView.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-09.
//

import SwiftUI

struct ChatCardView: View {
    @State var chat: Chat
    @EnvironmentObject var authVM: AuthViewModel
    
    private var otherParticipant: User? {
        // If it's a group, we don't need a specific other participant for the title/avatar usually,
        // unless we want to show who sent the last message.
        // For 1-on-1, we want the person who is NOT me.
        guard let currentUserID = authVM.currentUser?.id else { return nil }
        return chat.participants.first(where: { $0.id != currentUserID })
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Group {
                if let avatarURL = chat.isGroup ? chat.groupIconURL : otherParticipant?.avatarURL {
                    AsyncImage(url: avatarURL) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .overlay(Text(chat.isGroup ? "G" : (otherParticipant?.name.prefix(1) ?? "?")))
                    }
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 50, height: 50)
                        .overlay(Text(chat.isGroup ? "G" : (otherParticipant?.name.prefix(1) ?? "?")))
                }
            }//Group
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.isGroup ? (chat.groupName ?? "Group") : (otherParticipant?.name ?? "Unknown"))
                        .font(.headline)
                    Spacer()
                    if let lastMsg = chat.lastMessage {
                        Text(lastMsg.timestamp, style: .time)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }//HStack
                
                if let lastMsg = chat.lastMessage {
                    switch lastMsg.content {
                    case .text(let text):
                        Text(text)
                            .font(.subheadline)
                            .foregroundColor(.gray)
                            .lineLimit(1)
                    case .image:
                        Text("Image 📷")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    case .video:
                        Text("Video 🎥")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                }
            }//VStack
        }//HStack
    }
}

#Preview {
    let sampleUser = User(id: "1", name: "John Doe", isOnline: true)
    let sampleMessage = Message(
        senderId: "1",
        content: .text("Hey, how are you?"),
        timestamp: Date(),
        status: .delivered
    )
    let sampleChat = Chat(
        participants: [sampleUser],
        messages: [sampleMessage],
        isGroup: false
    )
    
    return ChatCardView(chat: sampleChat)
        .environmentObject(AuthViewModel())
}
