//
//  ChatViewApp.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-08.
//

import SwiftUI
import SwiftData

import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        print("Firebase Configured")
        
        handleFirstLaunch()
        
        return true
    }
    
    private func handleFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        
        if !hasLaunchedBefore {
            print("🆕 First launch after install detected. Clearing session...")
            // Clear Firebase session from Keychain
            do {
                try Auth.auth().signOut()
                print("✅ Persisted session cleared successfully.")
            } catch {
                print("⚠️ Error clearing persisted session: \(error.localizedDescription)")
            }
            
            // Set flag so this doesn't run again
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            UserDefaults.standard.synchronize()
        }
    }
}

@main
struct ChatViewApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var authVM = AuthVM()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            NavigationRoot {
                ChatListView()
            }
            .environmentObject(authVM)
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                authVM.updatePresence(isOnline: true)
            } else if newPhase == .background {
                authVM.updatePresence(isOnline: false)
            }
        }
    }

}
