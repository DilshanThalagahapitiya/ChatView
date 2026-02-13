//
//  SplashView.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-10.
//

import SwiftUI

struct SplashView: View {
    @State private var isAnimating = false
    @State private var circleScale: CGFloat = 0.5
    @State private var circleOpacity: Double = 0.0
    @State private var logoOpacity: Double = 0.0
    @State private var logoScale: CGFloat = 0.7
    @State private var textOffset: CGFloat = 20
    @State private var textOpacity: Double = 0.0
    
    var body: some View {
        ZStack {
            // Decorative background elements
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 400, height: 400)
                    .offset(x: -150, y: -250)
                    .blur(radius: 60)
                
                Circle()
                    .fill(Color.purple.opacity(0.15))
                    .frame(width: 300, height: 300)
                    .offset(x: 150, y: 250)
                    .blur(radius: 50)
            }
            
            VStack(spacing: 30) {
                // Logo Section with high-end animation
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 140, height: 140)
                        .scaleEffect(circleScale)
                        .opacity(circleOpacity)
                    
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.8)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)
                        .scaleEffect(logoScale)
                        .opacity(logoOpacity)
                }
                
                // Branding Section
                VStack(spacing: 12) {
                    Text("ChatView")
                        .font(.system(size: 48, weight: .black, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(1)
                        .opacity(textOpacity)
                        .offset(y: textOffset)
                    
                    Text("Connect. Share. Grow.")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.7))
                        .opacity(textOpacity)
                        .offset(y: textOffset)
                }
                
                // Subtle Loading
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
                    .padding(.top, 40)
                    .opacity(textOpacity)
            }
        }//ZStack
        .withBaseViewMod(isBackgroundAppear: true)
        .onAppear {
            startAnimations()
        }
    }
    
    private func startAnimations() {
        // Initial build up
        withAnimation(.spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0)) {
            circleScale = 1.0
            circleOpacity = 1.0
        }
        
        withAnimation(.spring(response: 0.6, dampingFraction: 0.6, blendDuration: 0).delay(0.2)) {
            logoScale = 1.0
            logoOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.8).delay(0.4)) {
            textOpacity = 1.0
            textOffset = 0
        }
        
        // Continuous subtle motion
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
            isAnimating = true
        }
    }
}

// Helper for Hex colors to ensure premium palette
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    SplashView()
}
