//
//  GrowClubPortfolioView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/29/24.
//

import SwiftUI

struct GrowClubPortfolioView: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    @EnvironmentObject var settingsService: SettingsService
    @EnvironmentObject var searchService: SearchService
    @EnvironmentObject var portfolioService: PortfolioService
    @State var segment: GrowthClubPortfolio = .accelerated
    
    var body: some View {
        NavigationStack(path: $appNavigationState.dividendNavigation) {
            VStack {
                Picker("", selection: $segment) {
                    ForEach(GrowthClubPortfolio.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                switch segment {
                case .accelerated:
                    StockListView(key: .acceleratedProfits)
                case .breakthrough:
                    StockListView(key: .breakthroughStocks)
                case .dividend:
                    StockListView(key: .eliteDividendPayers)
                case .growth:
                    StockListView(key: .growthInvestor)
                case .buy:
                    StockListView(key: .buy)
                case .sell:
                    StockListView(key: .sell)
                }
            }
            .navigationTitle("Platinum Growth")
            .searchable(text: $searchService.searchText, prompt: "Enter Stock Symbol")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    if portfolioService.showingProgress {
                        ProgressView("Loading...")
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.blue))
                            .padding(.trailing, 30)
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            settingsService.setShowActiveStocks()
                        } label: {
                            Label("Show Active Stocks", systemImage: settingsService.displayStocks == .showActiveStocks ? "checkmark.circle" : "circle")
                        }
                        Button {
                            settingsService.setShowAllStocks()
                        } label: {
                            Label("Show All Stocks", systemImage: settingsService.displayStocks == .showAllStocks ? "checkmark.circle" : "circle")
                        }
                        Button {
                            settingsService.setShowSoldStocks()
                        } label: {
                            Label("Show Sold Stocks", systemImage: settingsService.displayStocks == .showSoldStocks ? "checkmark.circle" : "circle")
                        }
                        Button {
                            
                        } label: {
                            Text("Cancel")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                    }
                }
            }
            .navigationDestination(for: DividendNavDestination.self) { state in
                switch state {
                case .stockDetailView(let parameters):
                    StockDetailView(paramters: parameters)
                case .dividendCreateView(_):
                    EmptyView()
                case .dividendEditView(let parameters):
                    DividendEditView(parameters: parameters)
                }
            }
        }
    }
}

#Preview {
    GrowClubPortfolioView()
}
