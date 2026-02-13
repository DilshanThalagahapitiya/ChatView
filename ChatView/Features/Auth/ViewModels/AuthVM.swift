import Foundation
import Combine

/// Manages authentication state and operations
@MainActor
class AuthVM: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var isCheckingSession = true
    @Published var errorMessage: String?
    
    private let authService: AuthService
    private var cancellables = Set<AnyCancellable>()
    
    init(authService: AuthService = FirebaseAuthService()) {
        self.authService = authService
        
        // Observe auth state changes
        authService.authStatePublisher
            .dropFirst() // Skip the initial nil value from CurrentValueSubject to prevent flicker
            .receive(on: DispatchQueue.main)
            .sink { [weak self] user in
                guard let self = self else { return }
                self.currentUser = user
                self.isAuthenticated = user != nil
                
                // Add a small artificial delay to prevent "flicker"
                // and give the splash screen animation time to show
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self.isCheckingSession = false
                }
            }
            .store(in: &cancellables)
    }
    
    func signUp(email: String, password: String, name: String) async {
        guard validateSignUpInput(email: email, password: password, name: name) else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signUp(email: email, password: password, name: name)
            currentUser = user
            isAuthenticated = true
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        guard validateSignInInput(email: email, password: password) else {
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let user = try await authService.signIn(email: email, password: password)
            currentUser = user
            isAuthenticated = true
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "An unexpected error occurred"
        }
        
        isLoading = false
    }
    
    func signOut() {
        do {
            try authService.signOut()
            currentUser = nil
            isAuthenticated = false
            errorMessage = nil
        } catch let error as AuthError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "Failed to sign out"
        }
    }
    
    func updatePresence(isOnline: Bool) {
        Task {
            try? await authService.updatePresence(isOnline: isOnline)
        }
    }
    
    // MARK: - Validation
    
    private func validateSignUpInput(email: String, password: String, name: String) -> Bool {
        if name.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your name"
            return false
        }
        
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your email"
            return false
        }
        
        if !isValidEmail(email) {
            errorMessage = "Please enter a valid email address"
            return false
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        
        return true
    }
    
    private func validateSignInInput(email: String, password: String) -> Bool {
        if email.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Please enter your email"
            return false
        }
        
        if password.isEmpty {
            errorMessage = "Please enter your password"
            return false
        }
        
        return true
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
}
