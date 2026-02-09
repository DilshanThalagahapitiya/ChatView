import Foundation

/// Represents a user participating in a chat.
struct User: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let email: String?
    let avatarURL: URL?
    var isOnline: Bool
    var lastSeen: Date?
    let createdAt: Date?
    
    init(id: String = UUID().uuidString, name: String, email: String? = nil, avatarURL: URL? = nil, isOnline: Bool = false, lastSeen: Date? = nil, createdAt: Date? = nil) {
        self.id = id
        self.name = name
        self.email = email
        self.avatarURL = avatarURL
        self.isOnline = isOnline
        self.lastSeen = lastSeen
        self.createdAt = createdAt
    }
}


/// Represents the type of content in a message.
enum MessageType: Codable, Hashable {
    case text(String)
    case image(Media)
    case video(Media)
}

/// Represents a media item (image or video) attached to a message.
struct Media: Identifiable, Codable, Hashable {
    let id: String
    let url: URL
    let type: MediaType
    let thumbnailURL: URL?
    
    enum MediaType: String, Codable {
        case image
        case video
    }
    
    init(id: String = UUID().uuidString, url: URL, type: MediaType, thumbnailURL: URL? = nil) {
        self.id = id
        self.url = url
        self.type = type
        self.thumbnailURL = thumbnailURL
    }
}

/// Represents a single message in a chat.
struct Message: Identifiable, Codable, Hashable {
    let id: String
    let senderId: String
    let content: MessageType
    let timestamp: Date
    var status: MessageStatus
    
    enum MessageStatus: String, Codable {
        case sending
        case sent
        case delivered
        case read
        case failed
    }
    
    init(id: String = UUID().uuidString, senderId: String, content: MessageType, timestamp: Date = Date(), status: MessageStatus = .sending) {
        self.id = id
        self.senderId = senderId
        self.content = content
        self.timestamp = timestamp
        self.status = status
    }
}

/// Represents a chat conversation (1-to-1 or group).
struct Chat: Identifiable, Codable, Hashable {
    let id: String
    var participants: [User]
    var messages: [Message]
    let isGroup: Bool
    let groupName: String?
    let groupIconURL: URL?
    var lastMessage: Message? {
        messages.last
    }
    var unreadCount: Int
    
    init(id: String = UUID().uuidString, participants: [User], messages: [Message] = [], isGroup: Bool = false, groupName: String? = nil, groupIconURL: URL? = nil, unreadCount: Int = 0) {
        self.id = id
        self.participants = participants
        self.messages = messages
        self.isGroup = isGroup
        self.groupName = groupName
        self.groupIconURL = groupIconURL
        self.unreadCount = unreadCount
    }
}
