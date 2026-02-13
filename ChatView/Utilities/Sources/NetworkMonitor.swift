//
//  NetworkMonitor.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-11.
//

import SwiftUI
import Network

@Observable
public final class NetworkMonitor {
    //===================================================================================================
    //functions for check internet avaiability before submiting the request / while prcessing the request
    //===================================================================================================
    
    // MARK: - Monitor Properties
    public private(set) var isNetworkConnected: Bool?
    public private(set) var connectionType: NWInterface.InterfaceType?
    
    private let queue = DispatchQueue(label: "NetworkMonitor")
    private let monitor = NWPathMonitor()
    private var isShowNetworkStatus: Bool = false
    
    // MARK: - Initialization
    public init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    // MARK: - Private Methods
    // Start monitoring
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            Task { @MainActor in
                self.isNetworkConnected = path.status == .satisfied
                self.connectionType = [.wifi, .cellular, .wiredEthernet]
                    .first(where: { path.usesInterfaceType($0) })
                
                if let isConnected = self.isNetworkConnected, isConnected,
                   let connectionType = self.connectionType, !self.isShowNetworkStatus {
                    print("\n♻️ =====>  Connected via \(connectionType)  <===== ♻️\n")
                    self.isShowNetworkStatus = true
                } else {
                    print("\n🚫 =====>  No internet connection  <===== 🚫\n")
                    self.isShowNetworkStatus = false
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    // Stop monitoring
    private func stopMonitoring() {
        monitor.cancel()
    }
}

