//
//  ChatInputView.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-09.
//

import SwiftUI
import PhotosUI

struct ChatInputView: View {
    @Binding var text: String
    var onSend: () -> Void
    @ObservedObject var vm: ChatViewModel // To observe media selection and limits
    
    @State private var selectedItem: PhotosPickerItem?
    
    var body: some View {
        VStack(spacing: 0) {
            
            // Media Preview Area
            if !vm.selectedMedia.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack {
                        ForEach(Array(vm.selectedMedia.enumerated()), id: \.element.id) { index, media in
                            MediaPreviewView(media: media) {
                                vm.removeMedia(at: index)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color.gray.opacity(0.1))
            }
            
            HStack(alignment: .bottom, spacing: 12) {
                // Media Picker Button
                PhotosPicker(selection: $selectedItem, matching: .any(of: [.images, .videos])) {
                    Image(systemName: "plus")
                    .font(.system(size: 20))
                    .foregroundColor(.blue)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
                }
                .onChange(of: selectedItem) { newItem in
                    Task {
                        if let item = newItem {
                            if let data = try? await item.loadTransferable(type: Data.self) {
                                // Save to temp file to get URL
                                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("jpg") // Simplify extension handling for demo
                                try? data.write(to: tempURL)
                                
                                let media = Media(url: tempURL, type: .image) // Simplify type detection for demo
                                vm.addMedia(media)
                            }
                            selectedItem = nil
                        }
                    }
                }
                
                // Text Field
                TextField("Type a message...", text: $text, axis: .vertical)
                    .padding(10)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(20)
                    .lineLimit(1...5)
                
                // Send Button
                Button(action: onSend) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor((text.isEmpty && vm.selectedMedia.isEmpty) ? .gray : .blue)
                        .rotationEffect(.degrees(45))
                }
                .disabled(text.isEmpty && vm.selectedMedia.isEmpty)
            }
            .padding()
            .background(Color.white) // Start with white background
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color.gray.opacity(0.2)),
                alignment: .top
            )
        }
    }
}
