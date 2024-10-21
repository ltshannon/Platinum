//
//  ContentView.swift
//  Platinum
//
//  Created by Larry Shannon on 6/12/24.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var dataModel: DataModel
    @EnvironmentObject var userAuth: Authentication
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var portfolioService: PortfolioService
    @StateObject var networkService = NetworkService()
    @State private var showSignIn: Bool = false
    @State var userId = ""
    
    var body: some View {
        TabView {
            GrowClubPortfolioView()
                .tabItem {
                    Label("Club Portfolio", systemImage: "rectangle.grid.2x2")
                }
            TotalsView()
                .tabItem {
                    Label("Totals", systemImage: "equal.circle")
                }
                .tag(5)
            DisplayModelPortfolioView()
                .tabItem {
                    Label("Model Portfolio", systemImage: "rectangle.grid.2x2")
                }
                .tag(6)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(7)
        }
        .onReceive(userAuth.$state) { state in
            debugPrint("😍", "ContentView onReceive userAtuh.state: \(state)")
            if state == .loggedOut {
                showSignIn = true
            }
            if state == .loggedIn {
                Task {
//                    await firebaseService.createUser(token: userAuth.fcmToken)
                    firebaseService.getUser()
                    portfolioService.loadPortfolios()
                }
                showSignIn = false
            }
        }
        .onReceive(userAuth.$fcmToken) { token in
            if token.isNotEmpty {
                Task {
                    await firebaseService.updateAddFCMToUser(token: userAuth.fcmToken)
                }
//                if userAuth.loginType == .apple {
//                    firebaseService.getUsers()
//                }
            }
        }
        .fullScreenCover(isPresented: $showSignIn) {
            SignInView()
        }

    }
}

#Preview {
    ContentView()
}
