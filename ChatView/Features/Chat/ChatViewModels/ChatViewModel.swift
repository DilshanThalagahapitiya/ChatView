//
//  ChatViewModel.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-10.
//

import Foundation
import Combine
import SwiftUI

@Observable
class ChatViewModel {
    var messages: [Message] = []
    var newMessageText: String = ""
    var selectedMedia: [Media] = []
    var isSending = false
    var isLoading = false
    var errorMessage: String?
    var isTyping = false

    // The current chat session being managed.
    var chat: Chat
    // The user currently logged in (for demo purposes).
    let currentUser: User 
    private let chatService: ChatService
    private var cancellables = Set<AnyCancellable>()

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
    
    //MARK: - SetupMessageListener
    private func setupMessageListener() {
//        print("👤 ChatViewModel: Setting up message listener for chat: \(chat.id)")
        isLoading = true
        chatService.listenToMessages(for: chat.id)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
//                print("🏁 ChatViewModel: Message listener completion: \(completion)")
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.errorMessage = "Failed to listen for messages: \(error.localizedDescription)"
                }
            } receiveValue: { [weak self] newMessages in
//                print("📬 ChatViewModel: Received \(newMessages.count) messages from listener")
                guard let self = self else { return }
                self.isLoading = false
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
            
        // Start listening to participant presence if 1-on-1
        if !chat.isGroup {
            for participant in chat.participants where participant.id != currentUser.id {
                chatService.listenToUserPresence(uid: participant.id)
                    .receive(on: DispatchQueue.main)
                    .sink { _ in } receiveValue: { [weak self] updatedUser in
                        guard let self = self else { return }
                        if let index = self.chat.participants.firstIndex(where: { $0.id == updatedUser.id }) {
                            self.chat.participants[index] = updatedUser
                            // Force objectWillChange if needed, though chat is part of Published state?
                            // Since Chat is a struct, we need a @Published var chat if we want it to trigger.
                            // Currently ChatViewModel only has messages as @Published.
                        }
                    }
                    .store(in: &cancellables)
            }
        }
    }
    
    //MARK: - Send Message
    @MainActor
    func sendMessage() async {
        guard !newMessageText.isEmpty || !selectedMedia.isEmpty else { return }
        guard !isSending else { return }
        
        isSending = true
        
        let textToSend = newMessageText
        let mediaToSend = selectedMedia
        
        // Optimistically clear inputs
        newMessageText = ""
        selectedMedia = []
        
        // 1. Send Text Message
        if !textToSend.isEmpty {
            var message = Message(senderId: currentUser.id, content: .text(textToSend), status: .sending)
            messages.append(message)
            
            do {
                var messageToSend = message
                messageToSend.status = .sent
                try await chatService.sendMessage(messageToSend, to: chat.id)
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index].status = .sent
                }
            } catch {
                errorMessage = "Failed to send text: \(error.localizedDescription)"
                if let index = messages.firstIndex(where: { $0.id == message.id }) {
                    messages[index].status = .failed
                }
                // restore text if failed? Usually not desired in chat apps, keep it in bubble as failed
            }
        }
        
        // 2. Send Media Messages
        for media in mediaToSend {
            var message = Message(senderId: currentUser.id, content: media.type == .image ? .image(media) : .video(media), status: .sending)
            messages.append(message)
            
            do {
                let uploadedURL = try await chatService.uploadMedia(media) 
                var messageToSend = message
                messageToSend.status = .sent
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
        
        isSending = false
    }
    
    //MARK: - Add Media
    func addMedia(_ media: Media) {
        guard selectedMedia.count < 5 else {
            errorMessage = "You can only select up to 5 images."
            return
        }
        selectedMedia.append(media)
    }
    //MARK: - Remove Media
    func removeMedia(at index: Int) {
        selectedMedia.remove(at: index)
    }
    //MARK: - Mark As Read
    func markChatAsRead() {
        Task {
            do {
                try await chatService.markChatAsRead(chat.id)
            } catch {
                print("Failed to mark chat as read: \(error)")
            }
        }
    }
}
