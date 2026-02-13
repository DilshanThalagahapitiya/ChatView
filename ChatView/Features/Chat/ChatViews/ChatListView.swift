//
//  ChatListView.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-09.
//

import SwiftUI

struct ChatListView: View {
    @State var vm: ChatListVM
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @EnvironmentObject private var authVM: AuthVM
    @State private var showingCreateGroup = false
    
    init(vm: ChatListVM = ChatListVM()) {
        _vm = State(initialValue: vm)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing:0){
                List {
                    ForEach(vm.chats) { chat in
                        Button {
                            if let currentUser = authVM.currentUser {
                                coordinator.push(.chatDetail(chat: chat, currentUser: currentUser))
                            }
                        } label: {
                            ChatCardView(chat: chat)
                                .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                Task { await vm.deleteChat(chat.id) }
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                        .listRowSeparator(.automatic)
                        .listRowBackground(Color.secondaryTextColor.opacity(0.35))
                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    }//ForEach
                }//List
                .listStyle(.automatic)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }//VStack
            
            if let error = vm.errorMessage {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Text(error)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Button("Retry") {
                        Task { await vm.fetchChats() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.8))
            }
            
            if vm.isLoading {
                LoadingOverlay(message: "Loading chats...")
            }
        }//ZStack
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                // User info and logout
                Menu {
                    if let user = authVM.currentUser {
                        Text(user.name)
                        Text(user.email ?? "")
                            .font(.caption)
                        Divider()
                    }
                    Button(role: .destructive) {
                        authVM.signOut()
                    } label: {
                        Label("Log Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "person.circle.fill")
                        .font(.title3)
                }
            }//ToolBarItem
            
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack{
                    Button(action: { showingCreateGroup = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }//HStack
            }//ToolBarItem
            
        }//ToolBar
        .sheet(isPresented: $showingCreateGroup) {
            GroupChatCreationView(availableUsers: vm.users) { name, participants in
                Task {
                    await vm.createChat(name: name, participants: participants)
                }
            }
        }
        .task {
            await vm.fetchChats()
            await vm.fetchUsers()
        }

    }
}

#Preview {
    let mockService = MockChatService()
    let mockVM = ChatListVM(chatService: mockService)
    let mockAuthVM = AuthVM()
    
    return NavigationStack {
        ChatListView(vm: mockVM)
            .environmentObject(NavigationCoordinator())
            .environmentObject(mockAuthVM)
    }
}
