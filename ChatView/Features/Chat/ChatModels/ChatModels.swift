//
//  ChatModels.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-09.
//

import Foundation

// MARK: - User
struct User: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let email: String?
    let avatarURL: URL?
    var isOnline: Bool
    var lastSeen: Date?
    let createdAt: Date?
    
    init(
        id: String = UUID().uuidString,
        name: String,
        email: String? = nil,
        avatarURL: URL? = nil,
        isOnline: Bool = false,
        lastSeen: Date? = nil,
        createdAt: Date? = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.createdAt = createdAt
    }
    
    // Returns a human-friendly string for the user's last activity
    var lastSeenFormatted: String {
        guard let lastSeen = lastSeen else { return "" }
        
        // Using RelativeDateTimeFormatter for localized, "human" strings (e.g., "2 hours ago")
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        
        let interval = Date().timeIntervalSince(lastSeen)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 { // Less than an hour
            return formatter.localizedString(fromTimeInterval: -interval)
        } else {
            return lastSeen.formatted(date: .omitted, time: .shortened)
        }
    }
}


// MARK: - Message Types
enum MessageType: Codable, Hashable {
    case text(String)
    case image(Media)
    case video(Media)
    
    /// A quick way to get a text preview of any message type
    var previewDisplay: String {
        switch self {
        case .text(let content): return content
        case .image: return "Photo"
        case .video: return "Video"
        }
    }
}

struct Media: Identifiable, Codable, Hashable {
    let id: String
    let url: URL
    let type: MediaType
    let thumbnailURL: URL?
    
    enum MediaType: String, Codable {
        case image, video
    }
    
    init(id: String = UUID().uuidString, url: URL, type: MediaType, thumbnailURL: URL? = nil) {
        self.id = id
        self.url = url
        self.type = type
        self.thumbnailURL = thumbnailURL
    }
}


// MARK: - Message
struct Message: Identifiable, Codable, Hashable {
    let id: String
    let senderId: String
    let content: MessageType
    let timestamp: Date
    var status: MessageStatus
    
    enum MessageStatus: String, Codable {
        case sending, sent, delivered, read, failed
    }
    
    init(
        id: String = UUID().uuidString,
        senderId: String,
        content: MessageType,
        timestamp: Date = Date(),
        status: MessageStatus = .sending
    ) {
        self.id = id
        self.senderId = senderId
        self.content = content
        self.timestamp = timestamp
        self.status = status
    }
}


// MARK: - Chat
struct Chat: Identifiable, Codable, Hashable {
    let id: String
    var participants: [User]
    var messages: [Message]
    let isGroup: Bool
    let groupName: String?
    let groupIconURL: URL?
    var unreadCount: Int
    
    var lastMessage: Message? {
        messages.last
    }
    
    init(
        id: String = UUID().uuidString,
        participants: [User],
        messages: [Message] = [],
        isGroup: Bool = false,
        groupName: String? = nil,
        groupIconURL: URL? = nil,
        unreadCount: Int = 0
    ) {
        self.id = id
        self.participants = participants
        self.messages = messages
        self.isGroup = isGroup
        self.groupName = groupName
        self.groupIconURL = groupIconURL
        self.unreadCount = unreadCount
    }
}


// MARK: - Preview Mock Data
extension Chat {
    static var previewChat: Chat {
        let user = User(name: "Dilshan")
        let msg = Message(senderId: user.id, content: .text("Hey there!"), status: .read)
        return Chat(participants: [user], messages: [msg], unreadCount: 2)
    }
}
