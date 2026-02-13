//
//  GroupChatCreationView.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-09.
//

import SwiftUI

struct GroupChatCreationView: View {
    @Environment(\.dismiss) var dismiss
    @State private var groupName = ""
    @State private var selectedParticipants: Set<User> = []
    let availableUsers: [User]
    
    var onCreate: (String?, [User]) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Group Details")) {
                    TextField("Group Name (Optional for 1-on-1)", text: $groupName)
                }
                
                Section(header: Text("Select Participants")) {
                    List(availableUsers) { user in
                        Button(action: {
                            if selectedParticipants.contains(user) {
                                selectedParticipants.remove(user)
                            } else {
                                selectedParticipants.insert(user)
                            }
                        }) {
                            HStack {
                                Text(user.name)
                                Spacer()
                                if selectedParticipants.contains(user) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }//HStack
                        }
                        .foregroundColor(.primary)
                    }//List
                }//Section
            }//Form
            .navigationTitle("New Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }//ToolBarItem
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        onCreate(groupName, Array(selectedParticipants))
                        dismiss()
                    }
                    .disabled(selectedParticipants.isEmpty || (selectedParticipants.count > 1 && groupName.isEmpty)) // Name required only for groups
                }//ToolBarItem
            }//ToolBar
        }//NavigationView
    }
}

#Preview {
    GroupChatCreationView(availableUsers: [
        User(id: "u1", name: "Alice"),
        User(id: "u2", name: "Bob"),
        User(id: "u3", name: "Charlie")
    ]) { name, participants in
        print("Creating chat: \(name ?? "unnamed") with \(participants.count) participants")
    }
}
