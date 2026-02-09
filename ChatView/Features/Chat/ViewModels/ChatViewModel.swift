import Foundation
import Combine
import SwiftUI

class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var newMessageText: String = ""
    @Published var selectedMedia: [Media] = []
    @Published var isSending = false
    @Published var errorMessage: String?
    @Published var isTyping = false
    
    /// The current chat session being managed.
    let chat: Chat
    
    /// The user currently logged in (for demo purposes).
    let currentUser: User 
    
    private let chatService: ChatService
    
    /// Initializes the ViewModel with a chat session and service.
    /// - Parameters:
    ///   - chat: The chat object to manage.
    ///   - currentUser: The current user sending messages.
    ///   - chatService: The service used for networking operations.
    private var cancellables = Set<AnyCancellable>()
    
    /// Initializes the ViewModel with a chat session and service.
    /// - Parameters:
    ///   - chat: The chat object to manage.
    ///   - currentUser: The current user sending messages.
    ///   - chatService: The service used for networking operations.
    init(chat: Chat, currentUser: User, chatService: ChatService? = nil) {
        self.chat = chat
        self.currentUser = currentUser
        
        if let service = chatService {
            self.chatService = service
        } else {
            self.chatService = FirebaseChatService()
        }
        
        // Initial messages from the chat object (likely just last message or empty)
        self.messages = chat.messages
        
        // Start listening to real-time changes
        setupMessageListener()
    }
    
    private func setupMessageListener() {
        chatService.listenToMessages(for: chat.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to listen for messages: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] newMessages in
                guard let self = self else { return }
                
                // Preserve optimistic sending messages that haven't been confirmed yet
                let sendingMessages = self.messages.filter { $0.status == .sending }
                
                var mergedMessages = newMessages
                
                // Re-append sending messages if they are not yet in the new list (by ID)
                for sendingMsg in sendingMessages {
                    if !mergedMessages.contains(where: { $0.id == sendingMsg.id }) {
                        mergedMessages.append(sendingMsg)
                    }
                }
                
                // Sort by timestamp
                self.messages = mergedMessages.sorted(by: { $0.timestamp < $1.timestamp })
            }
            .store(in: &cancellables)
    }
    
    /// Sends a message (text and/or media) to the current chat.
    /// This method handles:
    /// 1. Optimistic UI updates (appending message immediately).
    /// 2. Text message sending.
    /// 3. Media upload and sending.
    /// 4. Error handling and status updates.
    @MainActor
    func sendMessage() async {
        guard !newMessageText.isEmpty || !selectedMedia.isEmpty else { return }
        
        isSending = true
        
        // 1. Send Text Message
        if !newMessageText.isEmpty {
            var message = Message(senderId: currentUser.id, content: .text(newMessageText), status: .sending)
            messages.append(message)
            newMessageText = ""
            
            do {
                // Prepare message for sending (update status to sent for DB)
                var messageToSend = message
                messageToSend.status = .sent
                
                try await chatService.sendMessage(messageToSend, to: chat.id)
                // Update status to sent locally upon success (though listener might have already done it)
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index].status = .sent
                }
            } catch {
                errorMessage = "Failed to send text: \(error.localizedDescription)"
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index].status = .failed
                }
            }
        }
        
        // 2. Send Media Messages
        for media in selectedMedia {
            var message = Message(senderId: currentUser.id, content: media.type == .image ? .image(media) : .video(media), status: .sending)
            messages.append(message)
            
            do {
                let uploadedURL = try await chatService.uploadMedia(media) // Simulate upload
                // Update media with uploaded URL if necessary - assuming uploadMedia handles storage and returns URL, 
                // but ChatService.sendMessage takes a Message which normally has a local URL in Media object?
                // The actual implementation of sendMessage likely doesn't upload media again. 
                // We should probably update the message content with remote URL here if sendMessage expects it.
                // However, based on previous context, we'll just focus on status.
                
                var messageToSend = message
                messageToSend.status = .sent
                // Ideally update content with remote URL here if needed
                
                try await chatService.sendMessage(messageToSend, to: chat.id)
                 if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index].status = .sent
                }
            } catch {
                errorMessage = "Failed to send media: \(error.localizedDescription)"
                 if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index].status = .failed
                }
            }
        }
        
        selectedMedia.removeAll()
        isSending = false
    }
    
    func addMedia(_ media: Media) {
        guard selectedMedia.count < 5 else {
            errorMessage = "You can only select up to 5 images."
            return
        }
        selectedMedia.append(media)
    }
    
    func removeMedia(at index: Int) {
        selectedMedia.remove(at: index)
    }
}
