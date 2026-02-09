//
//  ChatDetailView.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-09.
//

import SwiftUI

struct ChatDetailView: View {
    @StateObject var vm: ChatViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Message List
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(vm.messages) { message in
                            MessageBubbleView(
                                message: message,
                                isCurrentUser: message.senderId == vm.currentUser.id
                            )
                            .id(message.id)
                        }
                    }
                    .padding(.top)
                }
                .onChange(of: vm.messages.count) { _ in
                    if let lastMessage = vm.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground)) // Subtle background
            
            // Input Area
            ChatInputView(
                text: $vm.newMessageText,
                onSend: {
                    Task {
                        await vm.sendMessage()
                    }
                },
                vm: vm // Pass VM for media handling
            )
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    // Title (Name)
                    Text(vm.chat.isGroup ? (vm.chat.groupName ?? "Group") : vm.chat.participants.first(where: { $0.id != vm.currentUser.id })?.name ?? "Chat")
                        .font(.headline)
                    
                    // Subtitle (Status)
                    if !vm.chat.isGroup, let otherUser = vm.chat.participants.first(where: { $0.id != vm.currentUser.id }) {
                        if otherUser.isOnline {
                            Text("Online")
                                .font(.caption2)
                                .foregroundColor(.green)
                        } else if let lastSeen = otherUser.lastSeen {
                            Text("Last seen \(lastSeen.formatted(date: .omitted, time: .shortened))")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                }
            }
        }
    }
}
