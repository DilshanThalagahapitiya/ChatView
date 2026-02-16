//
//  ChatDetailView.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-09.
//

import SwiftUI

struct ChatDetailView: View {
    @State var vm: ChatViewModel
    
    init(chat: Chat, currentUser: User) {
        _vm = State(initialValue: ChatViewModel(chat: chat, currentUser: currentUser))
    }
    
    var body: some View {
        @Bindable var vm = vm
        ZStack {
            VStack(spacing: 0) {
                // Message List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.messages) { message in
                                MessageBubbleView(
                                    message: message,
                                    isCurrentUser: message.senderId == vm.currentUser.id,
                                    senderName: vm.chat.participants.first(where: { $0.id == message.senderId })?.name,
                                    onEdit: {
                                        vm.startEditing(message)
                                    },
                                    onDelete: {
                                        vm.deleteMessage(message)
                                    }
                                )
                                .id(message.id)
                            }//ForEach
                        }//LVStak
                        .padding(.top)
                    }//ScrollView
                    .onChange(of: vm.messages.count) { _ in
                        if let lastMessage = vm.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }//ScrollViewReader

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
            }//VStack
            
            if let error = vm.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
            }
            
            if vm.isLoading {
                LoadingOverlay(message: "Loading messages...")
            }
        }//ZStack
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 2) {
                    Text(vm.chat.isGroup ? (vm.chat.groupName ?? "Group") : vm.chat.participants.first(where: { $0.id != vm.currentUser.id })?.name ?? "Chat")
                        .font(.headline)
                    
                    if !vm.chat.isGroup, let otherUser = vm.chat.participants.first(where: { $0.id != vm.currentUser.id }) {
                        RelativeStatusView(user: otherUser)
                    }
                }//VStack
            }//ToolBarItem
        }//ToolBar
        .task {
            vm.markChatAsRead()
        }
    }
}

#Preview {
    let mockUser = User(id: "current", name: "Me")
    let otherUser = User(id: "u1", name: "Alice", isOnline: true)
    let mockChat = Chat(id: "c1", participants: [mockUser, otherUser], messages: [
        Message(senderId: "u1", content: .text("Hey!"), timestamp: Date().addingTimeInterval(-3600), status: .read),
        Message(senderId: "current", content: .text("Hi Alice!"), timestamp: Date().addingTimeInterval(-3500), status: .read)
    ])
    let mockVM = ChatViewModel(chat: mockChat, currentUser: mockUser, chatService: MockChatService())
    
//    return NavigationStack {
//        ChatDetailView(vm: mockVM)
//    }
}
