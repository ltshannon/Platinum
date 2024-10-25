//
//  PlatinumApp.swift
//  Platinum
//
//  Created by Larry Shannon on 6/12/24.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        debugPrint("Firebase started")
        return true
    }
}

@main
struct PlatinumApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var dataModel = DataModel()
    @StateObject var portfolioService = PortfolioService()
    @StateObject var userAuth = Authentication.shared
    @StateObject var firebaseService = FirebaseService.shared
    @StateObject var platinumGrowthModel = PlatinumGrowthModel.shared
    @StateObject var appNavigationState = AppNavigationState()
    @StateObject var settingsService = SettingsService.shared
    @StateObject var searchService = SearchService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(dataModel)
                .environmentObject(userAuth)
                .environmentObject(firebaseService)
                .environmentObject(portfolioService)
                .environmentObject(platinumGrowthModel)
                .environmentObject(appNavigationState)
                .environmentObject(settingsService)
                .environmentObject(searchService)
        }
    }
}
