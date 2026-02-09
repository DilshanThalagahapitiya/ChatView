import Foundation
import Combine

class ChatListViewModel: ObservableObject {
    @Published var chats: [Chat] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    @Published var users: [User] = []
    
    private let chatService: ChatService
    
    init(chatService: ChatService? = nil) {
        if let service = chatService {
            self.chatService = service
        } else {
            self.chatService = FirebaseChatService()
        }
    }
    
    @MainActor
    func fetchChats() async {
        isLoading = true
        errorMessage = nil
        do {
            chats = try await chatService.fetchChats()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
    
    @MainActor
    func fetchUsers() async {
        do {
            users = try await chatService.fetchUsers()
        } catch {
            print("Failed to fetch users: \(error.localizedDescription)")
        }
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
        do {
            try await chatService.deleteChat(chatID)
            // Remove from local array immediately for better UX
            chats.removeAll { $0.id == chatID }
        } catch {
            errorMessage = "Failed to delete chat: \(error.localizedDescription)"
        }
    }
}
