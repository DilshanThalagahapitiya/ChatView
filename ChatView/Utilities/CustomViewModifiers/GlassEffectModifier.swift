//
//  glassmorphicCard.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-10.
//


import SwiftUI
import Foundation

extension View {
    @ViewBuilder
    func glassmorphicCard(isHidden: Bool = false,
                          backgroundCornerRadius: CGFloat = 24,
                          overlayCornerRadius: CGFloat = 28,
                          blurRadius: CGFloat = 1,
                          strokeOpacity: Double = 0.25,
                          strokeLineWidth: CGFloat = 1,
                          shadowRadius: CGFloat = 20,
                          shadowOpacity: Double = 0.03,
                          shadowY: CGFloat = 10) -> some View {
        
        modifier(GlassmorphicCardModifier(isHidden: isHidden,
                                          backgroundCornerRadius: backgroundCornerRadius,
                                          overlayCornerRadius: overlayCornerRadius,
                                          blurRadius: blurRadius,
                                          strokeOpacity: strokeOpacity,
                                          strokeLineWidth: strokeLineWidth,
                                          shadowRadius: shadowRadius,
                                          shadowOpacity: shadowOpacity,
                                          shadowY: shadowY))
    }
}

struct GlassmorphicCardModifier: ViewModifier {
    let isHidden: Bool
    let backgroundCornerRadius: CGFloat
    let overlayCornerRadius: CGFloat
    let blurRadius: CGFloat
    let strokeOpacity: Double
    let strokeLineWidth: CGFloat
    let shadowRadius: CGFloat
    let shadowOpacity: Double
    let shadowY: CGFloat
    
    func body(content: Content) -> some View {
        if !isHidden {
            content
                .background(
                    ZStack {
                        // Liquid glass effect - light background
                        RoundedRectangle(cornerRadius: backgroundCornerRadius)
                            .fill(LinearGradient(gradient: Gradient(colors: [Color.deepBlueColor.opacity(0.35),
                                                                             Color.deepBlueColor.opacity(0.25)
                                                                            ]),
                                                 startPoint: .topLeading,
                                                 endPoint: .bottomTrailing)
                            )
                            .blur(radius: 1)
                        
                        RoundedRectangle(cornerRadius: backgroundCornerRadius)
                            .strokeBorder(LinearGradient(colors: [.white.opacity(0.6), .white.opacity(0.15), .clear],
                                                         startPoint: .topLeading,
                                                         endPoint: .bottomTrailing),
                                          lineWidth: strokeLineWidth
                            )
                            .overlay(RoundedRectangle(cornerRadius: backgroundCornerRadius)
                                .strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                                .blur(radius: 0.5)
                            )
                    }//: ZStack
                )
                .overlay(RoundedRectangle(cornerRadius: overlayCornerRadius)
                    .stroke(Color.white.opacity(strokeOpacity), lineWidth: strokeLineWidth)
                )
                .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: shadowY)
        } else {
            content
        }
        
    }
}

#Preview {
    LoginView()
}
