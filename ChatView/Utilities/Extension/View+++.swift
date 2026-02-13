//
//  View+++.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-11.
//

import SwiftUI

extension View {
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
