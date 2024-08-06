//
//  GrowClubPortfolioView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/29/24.
//

import SwiftUI

struct GrowClubPortfolioView: View {
    @State var segment: GrowthClubPortfolio = .accelerated
    
    var body: some View {
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
    }
}

#Preview {
    GrowClubPortfolioView()
}
