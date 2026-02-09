import Foundation
import Combine
import SwiftUI

import FirebaseDatabase
import FirebaseStorage
import FirebaseAuth

class FirebaseChatService: ChatService {
    
    // MARK: - Properties
    
    private let database = Database.database().reference()
    
    private let storage = Storage.storage().reference()
    
    init() {
        // No need for anonymous auth - users must be authenticated via email/password
    }
    
    // MARK: - Auth Helper
    
    private func getCurrentUserID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ChatService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        return uid
    }


    // MARK: - ChatService Implementation
    
    func fetchChats() async throws -> [Chat] {
        let currentUserID = try getCurrentUserID()
        
        // 1. Fetch all chats
        let snapshot = try await database.child("chats").getData()
        var chats: [Chat] = []
        
        // 2. Collect all unique participant IDs from relevant chats
        var relevantChatSnapshots: [(DataSnapshot, [String: Any])] = []
        var userIDsToFetch: Set<String> = []
        
        for child in snapshot.children {
            if let snap = child as? DataSnapshot,
               let dict = snap.value as? [String: Any],
               let participantsDict = dict["participants"] as? [String: Any],
               participantsDict.keys.contains(currentUserID) {
                
                relevantChatSnapshots.append((snap, dict))
                userIDsToFetch.formUnion(participantsDict.keys)
            }
        }
        
        // 3. Fetch user profiles
        var userCache: [String: User] = [:]
        
        // Use a task group to fetch users concurrently
        try await withThrowingTaskGroup(of: (String, User?).self) { group in
            for uid in userIDsToFetch {
                group.addTask {
                    // Try to fetch user, return nil if failed but don't throw to keep going
                    do {
                        let user = try await self.getUserProfile(uid: uid)
                        return (uid, user)
                    } catch {
                        print("Failed to fetch user \(uid): \(error)")
                        return (uid, nil)
                    }
                }
            }
            
            for try await (uid, user) in group {
                if let user = user {
                    userCache[uid] = user
                }
            }
        }
        
        // 4. Construct Chat objects with real users
        for (snap, dict) in relevantChatSnapshots {
            // Manually construct Chat to inject real users
            var chatDict = dict
            // We use the dictionary initializer but updated participants logic
            
            if let chat = Chat(dictionary: chatDict, id: snap.key) {
                // Replace stub participants with real ones from cache
                let participantKeys = (dict["participants"] as? [String: Any])?.keys
                let participantIDs = participantKeys.map { Array($0) } ?? []
                let realParticipants = participantIDs.compactMap { userCache[$0] }
                
                var realChat = chat
                realChat.participants = realParticipants
                
                chats.append(realChat)
            }
        }

        return chats.sorted(by: { ($0.lastMessage?.timestamp ?? Date()) > ($1.lastMessage?.timestamp ?? Date()) })
    }
    
    func fetchMessages(for chatID: String) async throws -> [Message] {
        // In a real app, you'd likely use an observer here rather than a one-time fetch,
        // but for this async method signature, we'll do a one-time fetch.
        // The ViewModel should ideally subscribe to updates.
        
        let snapshot = try await database.child("messages").child(chatID).queryOrdered(byChild: "timestamp").getData()
        var messages: [Message] = []
        
        for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
            if let dict = child.value as? [String: Any],
               let message = Message(dictionary: dict, id: child.key) {
                messages.append(message)
            }
        }
        return messages
    }

    func listenToMessages(for chatID: String) -> AnyPublisher<[Message], Error> {
        let subject = PassthroughSubject<[Message], Error>()
        
        let handle = database.child("messages").child(chatID).queryOrdered(byChild: "timestamp").observe(.value) { snapshot in
            var messages: [Message] = []
            for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                if let dict = child.value as? [String: Any],
                   let message = Message(dictionary: dict, id: child.key) {
                    messages.append(message)
                }
            }
            subject.send(messages)
        } withCancel: { error in
            subject.send(completion: .failure(error))
        }
        
        return subject.handleEvents(receiveCancel: {
            self.database.child("messages").child(chatID).removeObserver(withHandle: handle)
        }).eraseToAnyPublisher()
    }

    // Helper to fetch single user
    private func getUserProfile(uid: String) async throws -> User {
        let snapshot = try await database.child("users").child(uid).getData()
        
        guard let dict = snapshot.value as? [String: Any],
              let name = dict["name"] as? String else {
            throw NSError(domain: "ChatService", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])
        }
        
        let email = dict["email"] as? String
        let isOnline = dict["isOnline"] as? Bool ?? false
        let lastSeen = (dict["lastSeen"] as? TimeInterval).map { Date(timeIntervalSince1970: $0) }
        
        return User(
            id: uid,
            name: name,
            email: email,
            isOnline: isOnline,
            lastSeen: lastSeen,
            createdAt: nil // Optional in this context
        )
    }

    
    func sendMessage(_ message: Message, to chatID: String) async throws {
        let msgDict = message.toDictionary()
        
        // 1. Add message to messages node
        try await database.child("messages").child(chatID).child(message.id).setValue(msgDict)
        
        // 2. Update last message in chat node
        let lastMessageDict: [String: Any] = [
            "lastMessage": msgDict,
            "updatedAt": ServerValue.timestamp()
        ]
        try await database.child("chats").child(chatID).updateChildValues(lastMessageDict)
    }
    
    func createChat(name: String?, participants: [User]) async throws -> Chat {
        let chatID = UUID().uuidString
        var participantsDict: [String: Any] = [:]
        for user in participants {
            participantsDict[user.id] = true // Using simple true for membership
        }
        
        // Add current user if not already in
        if let currentID = Auth.auth().currentUser?.uid {
            participantsDict[currentID] = true
        }
        
        let isGroup = participants.count > 1 || (name != nil && !name!.isEmpty)
        
        var chatDict: [String: Any] = [
            "id": chatID,
            "isGroup": isGroup,
            "participants": participantsDict,
            "updatedAt": ServerValue.timestamp()
        ]
        
        if let name = name, !name.isEmpty {
            chatDict["groupName"] = name
        }
        
        try await database.child("chats").child(chatID).setValue(chatDict)
        
        return Chat(id: chatID, participants: participants, isGroup: isGroup, groupName: name)
    }
    
    func uploadMedia(_ media: Media) async throws -> URL {
        let storageRef = storage.child("chat_media").child(UUID().uuidString)
        let metadata = StorageMetadata()
        metadata.contentType = media.type == .image ? "image/jpeg" : "video/mp4" // Simplify
        
        // Ensure we have data from the local URL
        let data = try Data(contentsOf: media.url)
        
        let _ = try await storageRef.putDataAsync(data, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL
    }
    
    func fetchUsers() async throws -> [User] {
        let currentUserID = try getCurrentUserID()
        let snapshot = try await database.child("users").getData()
        var users: [User] = []
        
        for child in snapshot.children {
            if let snap = child as? DataSnapshot,
               let dict = snap.value as? [String: Any],
               let name = dict["name"] as? String {
                let id = snap.key
                let email = dict["email"] as? String
                // Don't include yourself in the list of "other users"
                if id != currentUserID {
                    let user = User(
                        id: id,
                        name: name,
                        email: email,
                        isOnline: dict["isOnline"] as? Bool ?? false
                    )
                    users.append(user)
                }
            }
        }
        return users
    }
    
    func createMockUsers() async throws {
        let mockUsers = [
            ["id": "user_alice", "name": "Alice", "isOnline": true],
            ["id": "user_bob", "name": "Bob", "isOnline": false],
            ["id": "user_charlie", "name": "Charlie", "isOnline": true]
        ]
        
        for user in mockUsers {
            if let id = user["id"] as? String {
                 try await database.child("users").child(id).setValue(user)
            }
        }
    }
    
    func deleteChat(_ chatID: String) async throws {
        // Delete messages associated with the chat
        try await database.child("messages").child(chatID).removeValue()
        
        // Delete the chat itself
        try await database.child("chats").child(chatID).removeValue()
    }
}

// MARK: - Helper Extensions for Serialization

extension Chat {
    init?(dictionary: [String: Any], id: String) {
        self.id = id
        self.isGroup = dictionary["isGroup"] as? Bool ?? false
        self.groupName = dictionary["groupName"] as? String
        if let urlString = dictionary["groupIconURL"] as? String {
            self.groupIconURL = URL(string: urlString)
        } else {
            self.groupIconURL = nil
        }
        
        // Participants parsing would ideally fetch User profiles.
        // For now, we'll create stub users from IDs found in "participants"
        if let participantIds = (dictionary["participants"] as? [String: Any])?.keys {
            self.participants = participantIds.map { User(id: $0, name: "User \($0.prefix(4))") }
        } else {
            self.participants = []
        }
        
        self.messages = [] // Messages loaded separately
        self.unreadCount = 0
        
        if let lastMsgDict = dictionary["lastMessage"] as? [String: Any],
           let lastMsg = Message(dictionary: lastMsgDict, id: "last") {
            // self.lastMessage = lastMsg // Computed property in struct, so we can't set it directly. 
            // In a real app we might store it.
            self.messages = [lastMsg] 
        }
    }
}

extension Message {
    init?(dictionary: [String: Any], id: String) {
        guard let senderId = dictionary["senderId"] as? String,
              let timestamp = dictionary["timestamp"] as? TimeInterval, // Assume timestamp stored as TimeInterval
              let statusString = dictionary["status"] as? String,
              let typeString = dictionary["type"] as? String else { return nil }
        
        self.id = id
        self.senderId = senderId
        self.timestamp = Date(timeIntervalSince1970: timestamp)
        self.status = MessageStatus(rawValue: statusString) ?? .sent
        
        if typeString == "text", let text = dictionary["text"] as? String {
            self.content = .text(text)
        } else if (typeString == "image" || typeString == "video"),
                  let urlString = dictionary["url"] as? String,
                  let url = URL(string: urlString) {
             // simplified media reconstruction
            let media = Media(url: url, type: typeString == "image" ? .image : .video)
            self.content = typeString == "image" ? .image(media) : .video(media)
        } else {
            return nil
        }
    }
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "senderId": senderId,
            "timestamp": timestamp.timeIntervalSince1970,
            "status": status.rawValue
        ]
        
        switch content {
        case .text(let text):
            dict["type"] = "text"
            dict["text"] = text
        case .image(let media):
            dict["type"] = "image"
            dict["url"] = media.url.absoluteString
        case .video(let media):
            dict["type"] = "video"
            dict["url"] = media.url.absoluteString
        }
        
        return dict
    }
}
