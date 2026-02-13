//
//  LoadingOverlay.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-09.
//

import SwiftUI

struct LoadingOverlay: View {
    var message: String = "Loading..."
    
    var body: some View {
        ZStack {
            // Full-screen backdrop to dim underlying content
            Color.black.opacity(0.2)
                .ignoresSafeArea()
            
            // The frosted glass panel
            VStack(spacing: 24) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.white)
                
                Text(message)
                    .font(.system(.body, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            } //: VStack
            .padding(40)
            .background(.ultraThinMaterial) // Modern native glass effect
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(.white.opacity(0.15), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 10)
        } //: ZStack
    }
}

#Preview {
    ZStack {
        // Sample background to demonstrate transparency
        LinearGradient(
            colors: [.orange, .red],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        LoadingOverlay(message: "Syncing Data...")
    } //: ZStack
}
