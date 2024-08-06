//
//  EditStockListsView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/30/24.
//

import SwiftUI

struct ManageSymbolsView: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    @Environment(\.dismiss) private var dismiss
    @State var showingSheet: Bool = false
    @State var segment: GrowthClubPortfolio = .accelerated
    
    var body: some View {
        NavigationStack(path: $appNavigationState.symbolsNavigation) {
            VStack {
                Picker("", selection: $segment) {
                    ForEach(GrowthClubPortfolio.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                switch segment {
                case .accelerated:
                    ListSymbolsView(listName: convertToPortfolioType(item: segment))
                case .breakthrough:
                    ListSymbolsView(listName: convertToPortfolioType(item: segment))
                case .dividend:
                    ListSymbolsView(listName: convertToPortfolioType(item: segment))
                case .growth:
                    ListSymbolsView(listName: convertToPortfolioType(item: segment))
                case .buy:
                    ListSymbolsView(listName: convertToPortfolioType(item: segment))
                case .sell:
                    ListSymbolsView(listName: convertToPortfolioType(item: segment))
                }
                Group {
                    Button {
                        showingSheet = true
                    } label: {
                        Text("Add")
                    }
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .fullScreenCover(isPresented: $showingSheet, onDismiss: didDismiss) {
                AddSymbolView(listType: convertToPortfolioType(item: segment))
            }
            .navigationDestination(for: SymbolsNavDestination.self) { state in
                switch state {
                case .editSymbolsView(let parameters):
                    EditSymbolsView(paramters: parameters)
                }
            }
        }
    }
    
    func convertToPortfolioType(item: GrowthClubPortfolio) -> PortfolioType {
        switch item {
        case .accelerated:
            return PortfolioType.acceleratedProfits
        case .breakthrough:
            return PortfolioType.breakthroughStocks
        case .dividend:
            return PortfolioType.eliteDividendPayers
        case .growth:
            return PortfolioType.growthInvestor
        case .buy:
            return PortfolioType.buy
        case .sell:
            return PortfolioType.sell
        }
    }
    
    func didDismiss() {
        
    }
}

#Preview {
    ManageSymbolsView()
}
