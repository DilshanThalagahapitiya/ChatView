# Chat Module Integration Guide

This guide explains how to integrate the reusable Chat Module into your iOS application.

## 1. Installation

Copy the entire `Chat` folder from `Features/Chat` into your project's `Features` directory.

## 2. Dependencies

The module relies on the following standard libraries:
- `SwiftUI`
- `Combine`
- `PhotosUI` (for media picker)

Ensure your project target supports **iOS 16.0+** for the best compatibility with `PhotosPicker` and `AsyncImage`.

## 3. Usage

### Displaying the Chat List

To show the list of conversations, simply navigate to `ChatListView`.

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        ChatListView()
    }
}
```

### Customizing the Service

The module uses a `ChatService` protocol. By default, it uses `MockChatService` for demonstration. To use a real backend (e.g., Firebase, REST API):

1. Create a class that conforms to `ChatService`.
2. Inject it into `ChatListViewModel` and `ChatViewModel`.

```swift
class MyRealChatService: ChatService {
    // Implement protocol methods...
}

// In your app composition root:
let chatService = MyRealChatService()
let viewModel = ChatListViewModel(chatService: chatService)
```

### UI Customization

You can customize the look and feel by modifying `ChatConstants.swift` in `Features/Chat/Utilities/`.
- **Colors**: Change bubble colors, text colors.
- **Dimensions**: Adjust padding, corner radius, etc.

## 4. Key Components

- **ChatListView**: The entry point for the chat feature.
- **ChatDetailView**: The actual chat interface.
- **ChatViewModel**: Manages the logic for a single chat session.
- **ChatModels.swift**: Contains `User`, `Message`, `Chat`, `Media` structs.

## 5. Media Upload

The current `MockChatService` simulates media upload by returning the local URL. In a real app, implement the `uploadMedia` method in your service to upload the file to a server and return the remote URL.

## 6. Group Chat

Group creation is handled by `GroupChatCreationView`. You can trigger this from `ChatListView`. The `createGroupChat` method in `ChatService` handles the logic.

## 7. Using Firebase

To enable Firebase:
1. Follow the instructions in `FIREBASE_SETUP.md`.
2. Add the `FirebaseDatabase`, `FirebaseStorage`, and `FirebaseAuth` packages via Swift Package Manager.
3. The app will automatically detect the Firebase SDK and switch to `FirebaseChatService`.
4. Ensure `GoogleService-Info.plist` is in your project root.

The `ChatViewApp` is already configured to initialize Firebase if the modules are present.
