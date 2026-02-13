import Foundation
import Combine

protocol ChatService {
    /// Fetch the list of all chat conversations.
    func fetchChats() async throws -> [Chat]
    
    /// Fetch messages for a specific chat.
    /// - Parameter chatID: The ID of the chat.
    func fetchMessages(for chatID: String) async throws -> [Message]
    
    /// Listen for real-time message updates for a specific chat.
    /// - Parameter chatID: The ID of the chat.
    /// - Returns: A publisher that emits an array of messages whenever changes occur.
    func listenToMessages(for chatID: String) -> AnyPublisher<[Message], Error>
    
    /// Listen for real-time chat list updates.
    /// - Returns: A publisher that emits an array of chats whenever changes occur.
    func listenToChats() -> AnyPublisher<[Chat], Error>
    
    /// Mark a chat as read for the current user.
    /// - Parameter chatID: The ID of the chat.
    func markChatAsRead(_ chatID: String) async throws
    
    /// Listen for real-time presence updates for a specific user.
    /// - Parameter uid: The user ID.
    /// - Returns: A publisher that emits the updated User object.
    func listenToUserPresence(uid: String) -> AnyPublisher<User, Error>
    
    /// Send a message to a specific chat.
    /// - Parameters:
    ///   - message: The message object to send.
    ///   - chatID: The destination chat ID.
    func sendMessage(_ message: Message, to chatID: String) async throws
    
    /// Create a new chat (1-to-1 or group).
    /// - Parameters:
    ///   - name: The name of the group (optional). If nil, treated as 1-to-1 or auto-named.
    ///   - participants: The users to include in the chat.
    func createChat(name: String?, participants: [User]) async throws -> Chat
    
    /// Upload a media file (image/video).
    /// - Parameter media: The media object containing local URL and type.
    /// - Returns: The remote URL of the uploaded media.
    func uploadMedia(_ media: Media) async throws -> URL
    func fetchUsers() async throws -> [User]
    func createMockUsers() async throws // Add this for testing
    
    /// Delete a chat conversation.
    /// - Parameter chatID: The ID of the chat to delete.
    func deleteChat(_ chatID: String) async throws
}
