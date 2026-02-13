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
    private var rootListenerHandle: DatabaseHandle?
    
    init() {
        // Keep connection alive by adding a listener at the root metadata
        // This ensures the client stays "online" and ready for fetches.
//        rootListenerHandle = database.child(".info/connected").observe(.value) { snapshot in
//            if let connected = snapshot.value as? Bool, connected {
//                print("🟢 Firebase Realtime Database connected")
//            } else {
//                print("🔴 Firebase Realtime Database disconnected")
//            }
//        }
    }
    
    deinit {
        if let handle = rootListenerHandle {
            database.child(".info/connected").removeObserver(withHandle: handle)
        }
    }
    
    // MARK: - Auth Helper
    
    private func getCurrentUserID() throws -> String {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "ChatService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }
        return uid
    }

    // MARK: - Robust Fetch Helper
    
    private func getSnapshot(_ query: DatabaseQuery) async throws -> DataSnapshot {
        return try await withCheckedThrowingContinuation { continuation in
            query.observeSingleEvent(of: .value) { snapshot in
                continuation.resume(returning: snapshot)
            } withCancel: { error in
                continuation.resume(throwing: error)
            }
        }
    }

    // MARK: - ChatService Implementation
    
    //Fetch Chats.
    func fetchChats() async throws -> [Chat] {
        let currentUserID = try getCurrentUserID()
        
        // 1. Fetch all chats
        let snapshot = try await getSnapshot(database.child("chats"))
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
            
            if let chat = Chat(dictionary: chatDict, id: snap.key) {
                // Replace stub participants with real ones from cache
                let participantsDict = dict["participants"] as? [String: Any] ?? [:]
                let participantIDs = Array(participantsDict.keys)
                let realParticipants = participantIDs.compactMap { userCache[$0] }
                
                var realChat = chat
                realChat.participants = realParticipants
                
                chats.append(realChat)
            }
        }

        return chats.sorted(by: { ($0.lastMessage?.timestamp ?? Date()) > ($1.lastMessage?.timestamp ?? Date()) })
    }
    
    //Fetch Messages.
    func fetchMessages(for chatID: String) async throws -> [Message] {
        let snapshot = try await getSnapshot(database.child("messages").child(chatID).queryOrdered(byChild: "timestamp"))
        var messages: [Message] = []
        
        for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
            if let dict = child.value as? [String: Any],
               let message = Message(dictionary: dict, id: child.key) {
                messages.append(message)
            }
        }
        return messages
    }
    
    //Listen To Messages.
    func listenToMessages(for chatID: String) -> AnyPublisher<[Message], Error> {
//        print("📡 FirebaseChatService: Starting listener for chat: \(chatID)")
        let subject = CurrentValueSubject<[Message]?, Error>(nil)
        
        let handle = database.child("messages").child(chatID).queryOrdered(byChild: "timestamp").observe(.value) { snapshot in
//            print("📩 FirebaseChatService: Received snapshot for \(chatID) (\(snapshot.childrenCount) messages)")
            var messages: [Message] = []
            for child in snapshot.children.allObjects as? [DataSnapshot] ?? [] {
                if let dict = child.value as? [String: Any],
                   let message = Message(dictionary: dict, id: child.key) {
                    messages.append(message)
                }
            }
//            print("🚀 FirebaseChatService: Sending \(messages.count) parsed messages to subject")
            subject.send(messages)
        } withCancel: { error in
//            print("❌ FirebaseChatService: Listener cancelled for \(chatID): \(error.localizedDescription)")
            subject.send(completion: .failure(error))
        }
        
        return subject
            .compactMap { $0 }
            .handleEvents(receiveCancel: {
//                print("🛑 FirebaseChatService: Listener removed for \(chatID)")
                self.database.child("messages").child(chatID).removeObserver(withHandle: handle)
            })
            .eraseToAnyPublisher()
    }
    
    //Listen To Chats.
    func listenToChats() -> AnyPublisher<[Chat], Error> {
        let subject = CurrentValueSubject<[Chat]?, Error>(nil)
        
        let handle = database.child("chats").observe(.value) { [weak self] snapshot in
            guard let self = self else { return }
            
            Task {
                do {
                    let currentUserID = try self.getCurrentUserID()
                    var chats: [Chat] = []
                    
                    // 1. Collect all unique participant IDs from relevant chats
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
                    
                    // 2. Fetch user profiles
                    var userCache: [String: User] = [:]
                    
                    try await withThrowingTaskGroup(of: (String, User?).self) { group in
                        for uid in userIDsToFetch {
                            group.addTask {
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
                    
                    // 3. Construct Chat objects with real users
                    for (snap, dict) in relevantChatSnapshots {
                        if var chat = Chat(dictionary: dict, id: snap.key) {
                            let participantsDict = dict["participants"] as? [String: Any] ?? [:]
                            let participantIDs = Array(participantsDict.keys)
                            let realParticipants = participantIDs.compactMap { userCache[$0] }
                            
                            chat.participants = realParticipants
                            
                            // Extract unread count for current user
                            if let participantsDict = dict["participants"] as? [String: Any] {
                                if let userProps = participantsDict[currentUserID] as? [String: Any] {
                                    chat.unreadCount = userProps["unreadCount"] as? Int ?? 0
                                } else if let unread = participantsDict[currentUserID] as? Int {
                                    chat.unreadCount = unread
                                } else {
                                    chat.unreadCount = 0
                                }
                            }
                            
                            chats.append(chat)
                        }
                    }
                    
                    let sortedChats = chats.sorted(by: { ($0.lastMessage?.timestamp ?? Date.distantPast) > ($1.lastMessage?.timestamp ?? Date.distantPast) })
                    subject.send(sortedChats)
                    
                } catch {
                    subject.send(completion: .failure(error))
                }
            }
        } withCancel: { error in
            subject.send(completion: .failure(error))
        }
        
        return subject
            .compactMap { $0 }
            .handleEvents(receiveCancel: {
                self.database.child("chats").removeObserver(withHandle: handle)
            })
            .eraseToAnyPublisher()
    }

    // Helper to fetch single user
    private func getUserProfile(uid: String) async throws -> User {
        let snapshot = try await getSnapshot(database.child("users").child(uid))
        
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
            createdAt: nil
        )
    }

    //Send Message.
    func sendMessage(_ message: Message, to chatID: String) async throws {
        let msgDict = message.toDictionary()
        let currentUserID = try getCurrentUserID()
        
        // 1. Add message to messages node
        try await database.child("messages").child(chatID).child(message.id).setValue(msgDict)
        
        // 2. Fetch current participants to update unread counts
        let chatRef = database.child("chats").child(chatID)
        
        try await chatRef.runTransactionBlock({ (currentData: MutableData) -> TransactionResult in
            if var chatDict = currentData.value as? [String: Any] {
                // Update last message
                chatDict["lastMessage"] = msgDict
                chatDict["updatedAt"] = ServerValue.timestamp()
                
                // Update unread counts
                if var participants = chatDict["participants"] as? [String: Any] {
                    for (key, value) in participants {
                        if key == message.senderId {
                            // Reset sender's unread count to 0
                            if var participantData = value as? [String: Any] {
                                participantData["unreadCount"] = 0
                                participants[key] = participantData
                            } else {
                                participants[key] = ["unreadCount": 0]
                            }
                        } else {
                            // Increment for recipients
                            if var participantData = value as? [String: Any] {
                                let count = participantData["unreadCount"] as? Int ?? 0
                                participantData["unreadCount"] = count + 1
                                participants[key] = participantData
                            } else {
                                participants[key] = ["unreadCount": 1]
                            }
                        }
                    }
                    chatDict["participants"] = participants
                }
                
                currentData.value = chatDict
                return TransactionResult.success(withValue: currentData)
            }
            return TransactionResult.success(withValue: currentData)
        })
    }
    
    //Create Chat.
    func createChat(name: String?, participants: [User]) async throws -> Chat {
        let chatID = UUID().uuidString
        var participantsDict: [String: Any] = [:]
        
        // Initialize participants with unreadCount: 0
        for user in participants {
            participantsDict[user.id] = ["unreadCount": 0]
        }
        
        // Add current user if not already in
        if let currentID = Auth.auth().currentUser?.uid {
            participantsDict[currentID] = ["unreadCount": 0]
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
    
    //Upload Media.
    func uploadMedia(_ media: Media) async throws -> URL {
        let storageRef = storage.child("chat_media").child(UUID().uuidString)
        let metadata = StorageMetadata()
        metadata.contentType = media.type == .image ? "image/jpeg" : "video/mp4"
        
        let data = try Data(contentsOf: media.url)
        
        let _ = try await storageRef.putDataAsync(data, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        return downloadURL
    }
    
    //Fetch Users.
    func fetchUsers() async throws -> [User] {
        let currentUserID = try getCurrentUserID()
        let snapshot = try await getSnapshot(database.child("users"))
        var users: [User] = []
        
        for child in snapshot.children {
            if let snap = child as? DataSnapshot,
               let dict = snap.value as? [String: Any],
               let name = dict["name"] as? String {
                let id = snap.key
                let email = dict["email"] as? String
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
    
    //Create MockUsers For Testing.
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
    
    //Delete Chat.
    func deleteChat(_ chatID: String) async throws {
        try await database.child("messages").child(chatID).removeValue()
        try await database.child("chats").child(chatID).removeValue()
    }
    
    //Mark As Read.
    func markChatAsRead(_ chatID: String) async throws {
        let currentUserID = try getCurrentUserID()
        let ref = database.child("chats").child(chatID).child("participants").child(currentUserID)
        try await ref.updateChildValues(["unreadCount": 0])
    }
    
    //Listen To User Presence.
    func listenToUserPresence(uid: String) -> AnyPublisher<User, Error> {
        let subject = CurrentValueSubject<User?, Error>(nil)
        let ref = database.child("users").child(uid)
        
        let handle = ref.observe(.value) { snapshot in
            if let dict = snapshot.value as? [String: Any] {
                let name = dict["name"] as? String ?? "Unknown"
                let email = dict["email"] as? String
                let isOnline = dict["isOnline"] as? Bool ?? false
                
                let lastSeenDate: Date?
                if let ts = dict["lastSeen"] as? TimeInterval {
                    lastSeenDate = ts > 1000000000000 ? Date(timeIntervalSince1970: ts / 1000) : Date(timeIntervalSince1970: ts)
                } else {
                    lastSeenDate = nil
                }
                
                let user = User(
                    id: uid,
                    name: name,
                    email: email,
                    isOnline: isOnline,
                    lastSeen: lastSeenDate
                )
                subject.send(user)
            }
        } withCancel: { error in
            subject.send(completion: .failure(error))
        }
        
        return subject
            .compactMap { $0 }
            .handleEvents(receiveCancel: {
                ref.removeObserver(withHandle: handle)
            })
            .eraseToAnyPublisher()
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
        

        if let participantIds = (dictionary["participants"] as? [String: Any])?.keys {
            self.participants = participantIds.map { User(id: $0, name: "User \($0.prefix(4))") }
        } else {
            self.participants = []
        }
        
        self.messages = []
        self.unreadCount = 0
        
        if let lastMsgDict = dictionary["lastMessage"] as? [String: Any],
           let lastMsg = Message(dictionary: lastMsgDict, id: "last") {

            self.messages = [lastMsg] 
        }
    }
}

extension Message {
    init?(dictionary: [String: Any], id: String) {
        guard let senderId = dictionary["senderId"] as? String,
              let statusString = dictionary["status"] as? String,
              let typeString = dictionary["type"] as? String else { return nil }
        
        let timestamp: TimeInterval
        if let ts = dictionary["timestamp"] as? Double {
            timestamp = ts
        } else if let ts = dictionary["timestamp"] as? Int {
            // Handle cases where it might be stored as Int
            timestamp = TimeInterval(ts)
        } else {
            return nil
        }
        
        self.id = id
        self.senderId = senderId
        
        // Handle potential milliseconds vs seconds
        if timestamp > 1000000000000 { // Milliseconds
            self.timestamp = Date(timeIntervalSince1970: timestamp / 1000)
        } else {
            self.timestamp = Date(timeIntervalSince1970: timestamp)
        }
        
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
