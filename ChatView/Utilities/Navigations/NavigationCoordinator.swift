import SwiftUI
import Combine


/// Manages navigation state and provides navigation methods
@MainActor
class NavigationCoordinator: ObservableObject {
    @Published var path = NavigationPath()
    
    /// Navigate to a destination
    func push(_ destination: Destination) {
        path.append(destination)
    }
    
    /// Go back one screen
    func pop() {
        guard !path.isEmpty else { return }
        path.removeLast()
    }
    
    /// Return to root screen
    func popToRoot() {
        path = NavigationPath()
    }
    
    /// Replace current screen with a new destination
    func replace(with destination: Destination) {
        if !path.isEmpty {
            path.removeLast()
        }
        path.append(destination)
    }
    
    /// Get the current depth of the navigation stack
    var depth: Int {
        path.count
    }
}
