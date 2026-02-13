import Foundation
import FirebaseAuth
import FirebaseDatabase
import Combine

/// Firebase implementation of AuthService
class FirebaseAuthService: AuthService {
    private let auth = Auth.auth()
    private let database = Database.database().reference()
    private let authStateSubject = CurrentValueSubject<User?, Never>(nil)
    
    var currentUser: User? {
        authStateSubject.value
    }
    
    var authStatePublisher: AnyPublisher<User?, Never> {
        authStateSubject.eraseToAnyPublisher()
    }
    
    init() {
        // Listen to auth state changes
        auth.addStateDidChangeListener { [weak self] _, firebaseUser in
            guard let self = self else { return }
            
            if let firebaseUser = firebaseUser {
                // Fetch user profile from database
                print("🔄 Firebase User detected: \(firebaseUser.uid). Fetching profile...")
                Task {
                    do {
                        let user = try await self.fetchUserProfile(uid: firebaseUser.uid)
                        await MainActor.run {
                            self.authStateSubject.send(user)
                        }
                    } catch {
                        print("⚠️ Error fetching user profile for \(firebaseUser.uid): \(error)")
                        // Even if profile fetch fails, we should still signal an update 
                        // so AuthVM can move past 'isCheckingSession'.
                        // We send a basic user object if profile is missing for now.
                        await MainActor.run {
                            let placeholderUser = User(id: firebaseUser.uid, name: firebaseUser.displayName ?? "User", email: firebaseUser.email)
                            self.authStateSubject.send(placeholderUser)
                        }
                    }
                }
            } else {
                print("ℹ️ No Firebase User detected.")
                self.authStateSubject.send(nil)
            }
        }
    }

    
    func signUp(email: String, password: String, name: String) async throws -> User {
        do {
            // Create Firebase Auth user
            let authResult = try await auth.createUser(withEmail: email, password: password)
            
            // Create user profile
            let user = User(
                id: authResult.user.uid,
                name: name,
                email: email,
                isOnline: true,
                createdAt: Date()
            )
            
            // Save to database first
            try await saveUserProfile(user)
            
            // Update auth state immediately with the new user
            authStateSubject.send(user)
            
            return user
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }

    
    func signIn(email: String, password: String) async throws -> User {
        do {
            let authResult = try await auth.signIn(withEmail: email, password: password)
            
            // Fetch user profile
            let user = try await fetchUserProfile(uid: authResult.user.uid)
            
            // Update online status
            try await updateOnlineStatus(uid: user.id, isOnline: true)
            
            return user
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    func signOut() throws {
        // Update online status before signing out
        if let uid = auth.currentUser?.uid {
            Task {
                try? await updateOnlineStatus(uid: uid, isOnline: false)
            }
        }
        
        do {
            try auth.signOut()
            authStateSubject.send(nil)
        } catch let error as NSError {
            throw mapFirebaseError(error)
        }
    }
    
    func fetchUserProfile(uid: String) async throws -> User {
        let snapshot = try await database.child("users").child(uid).getData()
        
        guard let value = snapshot.value as? [String: Any] else {
            throw AuthError.userNotFound
        }
        
        return try parseUser(from: value, uid: uid)
    }
    
    // MARK: - Private Helpers
    
    private func saveUserProfile(_ user: User) async throws {
        let userData: [String: Any] = [
            "id": user.id,
            "name": user.name,
            "email": user.email ?? "",
            "isOnline": user.isOnline,
            "createdAt": user.createdAt?.timeIntervalSince1970 ?? Date().timeIntervalSince1970
        ]
        
        print("📝 Saving user profile to database: \(user.id)")
        try await database.child("users").child(user.id).setValue(userData)
        print("✅ User profile saved successfully: \(user.name)")
    }
    
    private func updateOnlineStatus(uid: String, isOnline: Bool) async throws {
        var updates: [String: Any] = ["isOnline": isOnline]
        
        if !isOnline {
            updates["lastSeen"] = ServerValue.timestamp()
        }
        
        try await database.child("users").child(uid).updateChildValues(updates)
    }
    
    func updatePresence(isOnline: Bool) async throws {
        guard let uid = auth.currentUser?.uid else { return }
        
        let userStatusRef = database.child("users").child(uid)
        let connectedRef = database.child(".info/connected")
        
        if isOnline {
            // Monitor connection state
            connectedRef.observe(.value) { snapshot in
                guard let connected = snapshot.value as? Bool, connected else { return }
                
                // When connected, set up onDisconnect once
                let statusDict: [String: Any] = [
                    "isOnline": true,
                    "lastSeen": ServerValue.timestamp()
                ]
                
                let offlineDict: [String: Any] = [
                    "isOnline": false,
                    "lastSeen": ServerValue.timestamp()
                ]
                
                // 1. Set onDisconnect handler
                userStatusRef.onDisconnectUpdateChildValues(offlineDict)
                
                // 2. Mark as online now
                userStatusRef.updateChildValues(statusDict)
            }
        } else {
            // Manually set to offline (e.g. background)
            // Remove observers to prevent auto-online if we explicitly want to be offline
            connectedRef.removeAllObservers()
            
            let offlineDict: [String: Any] = [
                "isOnline": false,
                "lastSeen": ServerValue.timestamp()
            ]
            try await userStatusRef.updateChildValues(offlineDict)
        }
    }
    
    private func parseUser(from data: [String: Any], uid: String) throws -> User {
        guard let name = data["name"] as? String else {
            throw AuthError.unknown("Invalid user data")
        }
        
        let email = data["email"] as? String
        let isOnline = data["isOnline"] as? Bool ?? false
        let lastSeenTimestamp = data["lastSeen"] as? TimeInterval
        let createdAtTimestamp = data["createdAt"] as? TimeInterval
        
        func parseDate(_ ts: TimeInterval?) -> Date? {
            guard let ts = ts else { return nil }
            // Handle precision: Firebase ServerValue.timestamp() is in milliseconds.
            // If > 10^12, it's likely milliseconds.
            if ts > 1_000_000_000_000 {
                return Date(timeIntervalSince1970: ts / 1000)
            }
            return Date(timeIntervalSince1970: ts)
        }
        
        return User(
            id: uid,
            name: name,
            email: email,
            isOnline: isOnline,
            lastSeen: parseDate(lastSeenTimestamp),
            createdAt: parseDate(createdAtTimestamp)
        )
    }
    
    private func mapFirebaseError(_ error: NSError) -> AuthError {
        // Check if this is a Firebase Auth error
        guard error.domain == AuthErrorDomain else {
            return .unknown(error.localizedDescription)
        }
        
        // Map Firebase Auth error codes
        switch error.code {
        case AuthErrorCode.invalidEmail.rawValue:
            return .invalidEmail
        case AuthErrorCode.weakPassword.rawValue:
            return .weakPassword
        case AuthErrorCode.emailAlreadyInUse.rawValue:
            return .emailAlreadyInUse
        case AuthErrorCode.userNotFound.rawValue:
            return .userNotFound
        case AuthErrorCode.wrongPassword.rawValue:
            return .wrongPassword
        case AuthErrorCode.networkError.rawValue:
            return .networkError
        default:
            return .unknown(error.localizedDescription)
        }
    }
}
