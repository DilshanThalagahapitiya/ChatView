//
//  SignupView.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-09.
//

import SwiftUI

struct SignupView: View {
    @EnvironmentObject private var authVM: AuthVM
    @EnvironmentObject private var coordinator: NavigationCoordinator
    
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email, password, confirmPassword
    }
    
    var passwordsMatch: Bool {
        password == confirmPassword && !password.isEmpty
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle.fill.badge.plus")
                            .font(.system(size: 70))
                            .foregroundStyle(.white)
                            .shadow(color: .black.opacity(0.2), radius: 10)
                        
                        Text("Create Account")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Text("Join the conversation")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.top, 60)
                    .padding(.bottom, 40)
                    
                    // Signup Form
                    VStack(spacing: 20) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person.fill")
                                    .foregroundStyle(.white.opacity(0.7))
                                    .frame(width: 20)
                                
                                TextField("Full Name", text: $name)
                                    .textContentType(.name)
                                    .focused($focusedField, equals: .name)
                                    .foregroundStyle(.white)
                                    .tint(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Email Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "envelope.fill")
                                    .foregroundStyle(.white.opacity(0.7))
                                    .frame(width: 20)
                                
                                TextField("Email", text: $email)
                                    .textContentType(.emailAddress)
                                    .keyboardType(.emailAddress)
                                    .autocapitalization(.none)
                                    .focused($focusedField, equals: .email)
                                    .foregroundStyle(.white)
                                    .tint(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                        }
                        
                        // Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.white.opacity(0.7))
                                    .frame(width: 20)
                                
                                SecureField("Password", text: $password)
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .password)
                                    .foregroundStyle(.white)
                                    .tint(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            
                            if !password.isEmpty && password.count < 6 {
                                Text("At least 6 characters required")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                                    .padding(.leading, 4)
                            }
                        }
                        
                        // Confirm Password Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.white.opacity(0.7))
                                    .frame(width: 20)
                                
                                SecureField("Confirm Password", text: $confirmPassword)
                                    .textContentType(.newPassword)
                                    .focused($focusedField, equals: .confirmPassword)
                                    .foregroundStyle(.white)
                                    .tint(.white)
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        !confirmPassword.isEmpty && !passwordsMatch ? Color.red.opacity(0.5) : Color.white.opacity(0.3),
                                        lineWidth: 1
                                    )
                            )
                            
                            if !confirmPassword.isEmpty && !passwordsMatch {
                                Text("Passwords don't match")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .padding(.leading, 4)
                            }
                        }
                        
                        // Error Message
                        if let error = authVM.errorMessage {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(error)
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(8)
                        }
                        
                        // Sign Up Button
                        Button {
                            focusedField = nil
                            guard passwordsMatch else {
                                authVM.errorMessage = "Passwords don't match"
                                return
                            }
                            Task {
                                await authVM.signUp(email: email, password: password, name: name)
                            }
                        } label: {
                            HStack {
                                if authVM.isLoading {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Text("Sign Up")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.3))
                            .foregroundStyle(.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.5), lineWidth: 1)
                            )
                        }
                        .disabled(authVM.isLoading || !passwordsMatch)
                        .padding(.top, 10)
                        
                        // Login Link
                        Button {
                            coordinator.pop()
                        } label: {
                            HStack(spacing: 4) {
                                Text("Already have an account?")
                                    .foregroundStyle(.white.opacity(0.8))
                                Text("Log In")
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                            .font(.subheadline)
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 32)
                    .padding(.bottom, 40)
                }
            }
            
            if authVM.isLoading {
                LoadingOverlay(message: "Creating account...")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .onSubmit {
            switch focusedField {
            case .name:
                focusedField = .email
            case .email:
                focusedField = .password
            case .password:
                focusedField = .confirmPassword
            case .confirmPassword:
                if passwordsMatch {
                    Task {
                        await authVM.signUp(email: email, password: password, name: name)
                    }
                }
            case .none:
                break
            }
        }
    }
}

#Preview {
    SignupView()
        .environmentObject(AuthVM())
        .environmentObject(NavigationCoordinator())
}
