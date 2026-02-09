//
//  ChatListView.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-09.
//

import SwiftUI

struct ChatListView: View {
    @StateObject private var vm = ChatListViewModel()
    @EnvironmentObject private var coordinator: NavigationCoordinator
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var showingCreateGroup = false
    
    var body: some View {
        List(vm.chats) { chat in
            Button {
                // Use authenticated user
                if let currentUser = authVM.currentUser {
                    coordinator.push(.chatDetail(chat: chat, currentUser: currentUser))
                }
            } label: {
                ChatCardView(chat: chat)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.plain) // Removes button styling to look like a list row
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    Task {
                        await vm.deleteChat(chat.id)
                    }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }//List
        .listStyle(.inset)
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
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { showingCreateGroup = true }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
        .sheet(isPresented: $showingCreateGroup) {
            GroupChatCreationView(availableUsers: vm.users) { name, participants in
                Task {
                    await vm.createChat(name: name, participants: participants)
                }
            }
        }
        .task {
            await vm.fetchUsers()
            await vm.fetchChats()
        }
    }
}
