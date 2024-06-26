//
//  TotalsView.swift
//  Platinum
//
//  Created by Larry Shannon on 6/23/24.
//

import SwiftUI

struct TotalsView: View {
    @EnvironmentObject var portfolioService: PortfolioService
    @State var acceleratedProfitsList: [ItemData] = []
    @State var acceleratedProfitsTotal: Decimal = 0
    @State var acceleratedProfitsStockList: [String] = []
    @State var breakthroughList: [ItemData] = []
    @State var breakthroughTotal: Decimal = 0
    @State var breakthroughStockList: [String] = []
    @State var eliteDividendPayersList: [ItemData] = []
    @State var eliteDividendPayersTotal: Decimal = 0
    @State var eliteDividendPayersStockList: [String] = []
    @State var growthInvestorList: [ItemData] = []
    @State var growthInvestorTotal: Decimal = 0
    @State var total: Decimal = 0
    let columns: [GridItem] = [
                                GridItem(.fixed(250), spacing: 5),
                                GridItem(.fixed(150), spacing: 5)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading) {
                    LazyVGrid(columns: columns, alignment: .leading) {
                        Group {
                            Text("Portfolio")
                            Text("Total")
                        }
                        Group {
                            Text("---------")
                            Text("-----")
                        }
                        ForEach(PortfolioType.allCases, id: \.id) { item in
                            Text(item.rawValue.camelCaseToWords())
                            switch item {
                            case .acceleratedProfits:
                                Text("$\(acceleratedProfitsTotal as NSDecimalNumber, formatter: currencyFormatter)")
                                    .foregroundStyle(acceleratedProfitsTotal < 0 ?.red : .green)
                            case .breakthroughStocks:
                                Text("$\(breakthroughTotal as NSDecimalNumber, formatter: currencyFormatter)")
                                    .foregroundStyle(breakthroughTotal < 0 ?.red : .green)
                            case .eliteDividendPayers:
                                Text("$\(eliteDividendPayersTotal as NSDecimalNumber, formatter: currencyFormatter)")
                                    .foregroundStyle(eliteDividendPayersTotal < 0 ?.red : .green)
                            case .growthInvestor:
                                Text("$\(growthInvestorTotal as NSDecimalNumber, formatter: currencyFormatter)")
                                    .foregroundStyle(growthInvestorTotal < 0 ?.red : .green)
                            }
                        }
                        Group {
                            Text("")
                            Text("-----------")
                        }
                        Group {
                            Text("Total")
                            Text("$\(total as NSDecimalNumber, formatter: currencyFormatter)")
                                .foregroundStyle(total < 0 ?.red : .green)
                        }
                    }
                    Spacer()
                    if portfolioService.isHidden == false {
                        ProgressView("Loading...", value: portfolioService.progress, total: 100)
                            .padding(.trailing, 30)
                    }
                }
            }
            .padding(.leading, 30)
            .navigationBarTitle("Investment Totals")
            .background {
                NavigationStyleLayer()
            }
            .refreshable {
                pullToRefresh()
            }
            .onAppear {
                acceleratedProfitsTotal = portfolioService.acceleratedProfitsTotal
                breakthroughTotal = portfolioService.breakthroughTotal
                eliteDividendPayersTotal = portfolioService.eliteDividendPayersTotal
                growthInvestorTotal = portfolioService.growthInvestorTotal
                computeTotal()
            }

            .onReceive(portfolioService.$acceleratedProfitsTotal) { total in
                acceleratedProfitsTotal = total
                computeTotal()
            }
            .onReceive(portfolioService.$breakthroughTotal) { total in
                breakthroughTotal = total
                computeTotal()
            }
            .onReceive(portfolioService.$eliteDividendPayersTotal) { total in
                eliteDividendPayersTotal = total
                computeTotal()
            }
            .onReceive(portfolioService.$growthInvestorTotal) { total in
                growthInvestorTotal = total
                computeTotal()
            }
        }
    }
    
    func computeTotal() {
        total = acceleratedProfitsTotal + breakthroughTotal + eliteDividendPayersTotal + growthInvestorTotal
    }
    
    func pullToRefresh() {
        refreshStocks()
    }
    
    func refreshStocks() {
        Task {
            portfolioService.loadPortfolios()
        }
    }
    
}

#Preview {
    TotalsView()
}
