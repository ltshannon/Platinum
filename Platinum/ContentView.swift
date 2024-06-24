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
            StockListView(key: .eliteDividendPayers)
                .tabItem {
                    Label("Dividend", systemImage: "rectangle.grid.2x2")
                }
                .tag(1)
            StockListView(key: .growthInvestor)
                .tabItem {
                    Label("Growth", systemImage: "rectangle.grid.2x2")
                }
                .tag(2)
            StockListView(key: .breakthroughStocks)
                .tabItem {
                    Label("Breakthrough", systemImage: "rectangle.grid.2x2")
                }
                .tag(3)
            StockListView(key: .acceleratedProfits)
                .tabItem {
                    Label("Accelerated", systemImage: "rectangle.grid.2x2")
                }
                .tag(4)
            TotalsView()
                .tabItem {
                    Label("Totals", systemImage: "equal.circle")
                }
                .tag(5)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(6)
        }
        .onReceive(userAuth.$state) { state in
            debugPrint("😍", "ContentView onReceive userAtuh.state: \(state)")
            if state == .loggedOut {
                showSignIn = true
            }
            if state == .loggedIn {
                Task {
                    await firebaseService.createUser(token: userAuth.fcmToken)
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
