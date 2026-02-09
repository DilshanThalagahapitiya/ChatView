import Foundation
import Combine

/// Protocol defining authentication operations
protocol AuthService {
    /// Current authenticated user
    var currentUser: User? { get }
    
    /// Publisher for auth state changes
    var authStatePublisher: AnyPublisher<User?, Never> { get }
    
    /// Sign up a new user with email and password
    func signUp(email: String, password: String, name: String) async throws -> User
    
    /// Sign in an existing user
    func signIn(email: String, password: String) async throws -> User
    
    /// Sign out the current user
    func signOut() throws
    
    /// Fetch user profile from database
    func fetchUserProfile(uid: String) async throws -> User
}

/// Authentication errors
enum AuthError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case networkError
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address"
        case .weakPassword:
            return "Password must be at least 6 characters"
        case .emailAlreadyInUse:
            return "This email is already registered"
        case .userNotFound:
            return "No account found with this email"
        case .wrongPassword:
            return "Incorrect password"
        case .networkError:
            return "Network error. Please check your connection"
        case .unknown(let message):
            return message
        }
    }
}
