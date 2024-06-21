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
    @StateObject var networkService = NetworkService()
    @StateObject var swiftSoupService = SwiftSoupService()
    @State private var showSignIn: Bool = false
    @State var userId = ""
    
    var body: some View {
        TabView {
            StockListView(key: "EliteDividendPayers")
                .tabItem {
                    Label("Elite", systemImage: "rectangle.grid.2x2")
                }
                .tag(1)
            StockListView(key: "GrowthInvestor")
                .tabItem {
                    Label("Growth", systemImage: "rectangle.grid.2x2")
                }
                .tag(2)
            StockListView(key: "BreakthroughStocks")
                .tabItem {
                    Label("Breakthrough", systemImage: "rectangle.grid.2x2")
                }
                .tag(3)
            StockListView(key: "AcceleratedProfits")
                .tabItem {
                    Label("Accelerated", systemImage: "rectangle.grid.2x2")
                }
                .tag(4)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(5)
        }
        .onReceive(userAuth.$state) { state in
            debugPrint("😍", "ContentView onReceive userAtuh.state: \(state)")
            if state == .loggedOut {
                showSignIn = true
            }
            if state == .loggedIn {
                Task {
                    await firebaseService.createUser(token: userAuth.fcmToken)
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
//        VStack {
//            ForEach(networkService.stockData) { item in
//                HStack {
//                    Text(item.id)
//                    Text(item.price, format: .currency(code: "USD"))
//                }
//            }
//            ForEach(swiftSoupService.eliteDividendPayersArray, id: \.self) { item in
//                Text(item)
//            }
//            Button {
//                swiftSoupService.fetch()
//            } label: {
//                Text("Get data no passowrd")
//            }
//            Button {
//                swiftSoupService.fetchWithPassword()
//            } label: {
//                Text("Get data with passowrd")
//            }
//        }
//        .padding()
//        .onAppear {
////            networkService.fetch(tickers: "AAPL,IBM")
//            
//        }
    }
}

#Preview {
    ContentView()
}
