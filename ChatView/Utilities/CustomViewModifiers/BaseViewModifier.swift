//
//  BaseViewModifier.swift
//  ChatView
//
//  Created by Dilshan Thalagahapitiya on 2026-02-11.
//

import SwiftUI

extension View {
    func withBaseViewMod(isBackgroundAppear: Bool = true) -> some View {
                    modifier(BaseViewModifier(isBackgroundAppear: isBackgroundAppear))
    }
}
struct BaseViewModifier: ViewModifier {
    //MARK: - For Network Monitoring Indicator
    static var networkMonitor = NetworkMonitor()
    @State private var networkMonitorIndicatorAutoDismissTime: TimeInterval = 2.0   /// 2 Seconds
    @State private var isShowNetworkMonitoringIndicator: Bool = false
    
    static var networkMonitorIndicatorString: String {
        var indicatorText: String = ""
        if let isConnected = networkMonitor.isNetworkConnected, isConnected,
           let connectionType = networkMonitor.connectionType {
            indicatorText = String(format: ".ConnectedVia", connectionType as? CVarArg ?? "Unknown Type" )
        } else {
            indicatorText = ".NoInternetConnection"
        }
        
        return indicatorText
    }
    
    //MARK: - For App Footer Details
    static var currentYear: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy"
        
        return dateFormatter.string(from: Date())
    }
    
    static var versionString: String {
        let appVersionString: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
        //        let buildNumber: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as! String
        
        return "Ver. \(appVersionString)"
    }
    
    //MARK: -  For View Animations
    @State var isBackgroundAppear: Bool = true

    
    
    func body(content: Content) -> some View {
        ZStack(alignment: .center) {
            GeometryReader { geometry in
                    if isBackgroundAppear {
                        LinearGradient(
                            colors: [
                                Color.deepBlue, // Deep Blue
                                Color.brightCyan  // Bright Cyan
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        .ignoresSafeArea()
                    }
            }
            .ignoresSafeArea()
            
            content   // main content
            VStack {
                Spacer()
                // MARK: - Network Monitoring Indicator
                if isShowNetworkMonitoringIndicator {
                    networkIndicatorView()
                        .transition(.move(edge: .bottom))
                }
            }//: VStack
            .onChange(of: BaseViewModifier.networkMonitor.isNetworkConnected) { newValue, oldValue in
                handleNetworkChange(newValue: newValue)
            }
            
            //MARK: - Keyboard Dismiss
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    keyboardTopToolbar()
                }
            }
            // Remove the rounded keyboard toolbar background on iPhone while
            // keeping the default appearance on iPad (iOS 16+ only).
            .modifier(KeyboardToolbarBackgroundModifier())
        }//: ZStack
        .edgesIgnoringSafeArea(.bottom)
    }

    // MARK: - Network Indicator View
    @ViewBuilder
    private func networkIndicatorView() -> some View {
        VStack {
            Text(BaseViewModifier.networkMonitorIndicatorString)
                .font(.footnote)
                .frame(maxWidth: .infinity)
                .padding(.top, 5)
                .padding(.bottom, 15)
                .background(networkIndicatorColor())
                .foregroundColor(networkForegroundColor())
        }//: VStack
    }
    
    @MainActor
    private func handleNetworkChange(newValue: Bool?) {
        guard newValue == true else {
            Task {
                try await Task.sleep(for: .seconds(networkMonitorIndicatorAutoDismissTime))
                withAnimation {
                    isShowNetworkMonitoringIndicator = false
                }
            }
            return
        }
        withAnimation {
            isShowNetworkMonitoringIndicator = true
        }
    }
    
    // MARK: - Helpers for Network Indicator
    private func networkIndicatorColor() -> Color {
        BaseViewModifier.networkMonitor.isNetworkConnected == true ? .green.opacity(0.9) : .red.opacity(0.9)
    }
    
    private func networkForegroundColor() -> Color {
        BaseViewModifier.networkMonitor.isNetworkConnected == true ? .primary : .white
    }

    
    // MARK: - Keyboard Dismiss Area
    @ViewBuilder
    private func keyboardTopToolbar() -> some View {
        Button(action: {
            UIApplication.shared.endEditing()
        }, label: {
            Image(systemName: "keyboard.chevron.compact.down")
                .renderingMode(.template)
                .foregroundColor(.accentColor)
                .glassmorphicCard()
        })
    }
}

/// Keeps keyboard toolbar background visible on iPad and hidden on iPhone where available.
private struct KeyboardToolbarBackgroundModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(#selector(UIResponder.resignFirstResponder),
                   to: nil,
                   from: nil,
                   for: nil)
    }
}
