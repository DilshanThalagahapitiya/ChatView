//
//  ChatListVM.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-10.
//

import Foundation
import Combine

@Observable
class ChatListVM {
    var chats: [Chat] = []
    var isLoading = false
    var errorMessage: String?
    var users: [User] = []
    
    private let chatService: ChatService
    
    private var chatSubscription: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    init(chatService: ChatService? = nil) {
        if let service = chatService {
            self.chatService = service
        } else {
            self.chatService = FirebaseChatService()
        }
    }
    
    @MainActor
    func fetchChats() async {
        // Prevent multiple active subscriptions, but allow re-subscription if it finished or failed
        if chatSubscription != nil && !isLoading {
             // If already observing and not currently loading, we are good.
             // However, to be safe and allow refresh, we can cancel and restart if called manually.
             return 
        }
        
        isLoading = true
        errorMessage = nil
        
        // Use real-time listener instead of one-time fetch
        chatSubscription = chatService.listenToChats()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }
                self.isLoading = false
                if case .failure(let error) = completion {
                    self.errorMessage = error.localizedDescription
                    // Clear subscription on failure so we can try again
                    self.chatSubscription = nil
                }
            } receiveValue: { [weak self] chats in
                self?.chats = chats
                self?.isLoading = false
            }
    }
    
    @MainActor
    func fetchUsers() async {
        isLoading = true
        do {
            users = try await chatService.fetchUsers()
        } catch {
            print("Failed to fetch users: \(error.localizedDescription)")
        }
        isLoading = false
    }
    
    @MainActor
    func createChat(name: String?, participants: [User]) async {
        isLoading = true
        do {
            let _ = try await chatService.createChat(name: name, participants: participants)
            await fetchChats() // Refresh list
        } catch {
            errorMessage = "Failed to create chat: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    @MainActor
    func seedUsers() async {
        isLoading = true
        do {
            try await chatService.createMockUsers()
            await fetchUsers() // Refresh list to show new users
        } catch {
            errorMessage = "Failed to seed users: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    @MainActor
    func deleteChat(_ chatID: String) async {
        isLoading = true
        do {
            try await chatService.deleteChat(chatID)
            // Remove from local array immediately for better UX
            chats.removeAll { $0.id == chatID }
        } catch {
            errorMessage = "Failed to delete chat: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    @MainActor
    func markAsRead(chat: Chat) async {
        guard chat.unreadCount > 0 else { return }
        do {
            try await chatService.markChatAsRead(chat.id)
            // Local update not strictly necessary due to listener, but good for responsiveness
            if let index = chats.firstIndex(where: { $0.id == chat.id }) {
                chats[index].unreadCount = 0
            }
        } catch {
            print("Failed to mark chat as read: \(error)")
        }
    }
}
