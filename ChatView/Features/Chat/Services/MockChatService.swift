import Foundation

//class MockChatService: ChatService {
//    
//    private var chats: [Chat] = []
//    
//    init() {
//        // Initialize with some dummy data
//        let user1 = User(id: "u1", name: "Alice", isOnline: true)
//        let user2 = User(id: "u2", name: "Bob", isOnline: false, lastSeen: Date().addingTimeInterval(-3600))
//        let currentUser = User(id: "current", name: "Me", isOnline: true)
//        
//        let msg1 = Message(senderId: "u1", content: .text("Hey there!"), timestamp: Date().addingTimeInterval(-86400), status: .read)
//        let msg2 = Message(senderId: "current", content: .text("Hi Alice! How are you?"), timestamp: Date().addingTimeInterval(-80000), status: .read)
//        
//        let chat1 = Chat(id: "c1", participants: [user1, currentUser], messages: [msg1, msg2], isGroup: false)
//        
//        let msg3 = Message(senderId: "u2", content: .text("Meeting at 3?"), timestamp: Date().addingTimeInterval(-100), status: .delivered)
//        let chat2 = Chat(id: "c2", participants: [user2, currentUser], messages: [msg3], isGroup: false)
//        
//        self.chats = [chat1, chat2]
//    }
//    
//    func fetchChats() async throws -> [Chat] {
//        // Simulate network delay
//        try? await Task.sleep(nanoseconds: 500_000_000)
//        return chats
//    }
//    
//    func fetchMessages(for chatID: String) async throws -> [Message] {
//        try? await Task.sleep(nanoseconds: 300_000_000)
//        guard let chat = chats.first(where: { $0.id == chatID }) else {
//            throw NSError(domain: "ChatError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Chat not found"])
//        }
//        return chat.messages
//    }
//    
//    func sendMessage(_ message: Message, to chatID: String) async throws {
//        try? await Task.sleep(nanoseconds: 300_000_000)
//        if let index = chats.firstIndex(where: { $0.id == chatID }) {
//            chats[index].messages.append(message)
//        } else {
//            throw NSError(domain: "ChatError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Chat not found"])
//        }
//    }
//    
//    func createChat(name: String?, participants: [User]) async throws -> Chat {
//        try? await Task.sleep(nanoseconds: 500_000_000)
//        let isGroup = participants.count > 1 || (name != nil && !name!.isEmpty)
//        let newChat = Chat(id: UUID().uuidString, participants: participants, isGroup: isGroup, groupName: name)
//        chats.append(newChat)
//        return newChat
//    }
//    
//    func uploadMedia(_ media: Media) async throws -> URL {
//        try? await Task.sleep(nanoseconds: 1_000_000_000)
//        // Return the local URL as if it was uploaded and we got a remote URL back
//        return media.url
//    }
//    
//    func fetchUsers() async throws -> [User] {
//        return [
//            User(id: "u1", name: "Alice", isOnline: true),
//            User(id: "u2", name: "Bob", isOnline: false),
//            User(id: "u3", name: "Charlie", isOnline: true)
//        ]
//    }
//    
//    func createMockUsers() async throws {
//        // No-op for mock service
//    }
//}
