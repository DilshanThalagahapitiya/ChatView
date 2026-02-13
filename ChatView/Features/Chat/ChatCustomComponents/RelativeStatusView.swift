//
//  RelativeStatusView.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-09.
//

import SwiftUI
import Combine

struct RelativeStatusView: View {
    let user: User
    @State private var relativeTime: String = ""
    
    // A 30-second heart beat to keep the "Last seen" text fresh
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()
    
    var body: some View {
        Text(statusText)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(user.isOnline ? .green : .secondary)
            .onAppear(perform: updateTime)
            .onReceive(timer) { _ in updateTime() }
            .onChange(of: user.lastSeen) { updateTime() }
    } //: body
    
    /// Logic to determine the displayed string based on connectivity status
    private var statusText: String {
        if user.isOnline {
            return "Online"
        } else if let _ = user.lastSeen {
            return "Last seen \(relativeTime)"
        }
        return ""
    }
    
    /// Updates the state variable with a human-readable duration
    private func updateTime() {
        relativeTime = user.lastSeenFormatted
    }
} //: RelativeStatusView
