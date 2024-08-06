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
    @State var acceleratedProfitsTotalBasis: Decimal = 0
    @State var acceleratedProfitsStockList: [String] = []
    @State var breakthroughList: [ItemData] = []
    @State var breakthroughTotal: Decimal = 0
    @State var breakthroughTotalBasis: Decimal = 0
    @State var breakthroughStockList: [String] = []
    @State var eliteDividendPayersList: [ItemData] = []
    @State var eliteDividendPayersTotal: Decimal = 0
    @State var eliteDividendPayersTotalBasis: Decimal = 0
    @State var eliteDividendPayersStockList: [String] = []
    @State var growthInvestorList: [ItemData] = []
    @State var growthInvestorTotal: Decimal = 0
    @State var growthInvestorTotalBasis: Decimal = 0
    @State var buyTotal: Decimal = 0
    @State var sellTotal: Decimal = 0
    @State var total: Decimal = 0
    @State var totalBasis: Decimal = 0
    @State var totalValue: Decimal = 0
    @State var totalDividend: Decimal = 0
    @State var dividendList: [DividendDisplayData] = []
    let columns: [GridItem] = [
                                GridItem(.adaptive(minimum: 250)),
                                GridItem(.adaptive(minimum: 150))
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if portfolioService.showingProgress {
                    ProgressView("Loading...")
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.blue))
                        .padding(.trailing, 30)
                }
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
                            if item != .buy && item != .sell {
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
                                case .buy:
                                    EmptyView()
                                    Text("$\(buyTotal as NSDecimalNumber, formatter: currencyFormatter)")
                                        .foregroundStyle(buyTotal < 0 ?.red : .green)
                                case .sell:
                                    EmptyView()
                                    Text("$\(sellTotal as NSDecimalNumber, formatter: currencyFormatter)")
                                        .foregroundStyle(buyTotal < 0 ?.red : .green)
                                }
                            }
                        }
                        Group {
                            Text("Dividends")
                            Text("$\(totalDividend as NSDecimalNumber, formatter: currencyFormatter)")
                                .foregroundStyle(total < 0 ?.red : .green)
                        }
                        Group {
                            Text("")
                            Text("-----------")
                        }
                        Group {
                            Text("Total Increase")
                            Text("$\(total as NSDecimalNumber, formatter: currencyFormatter)")
                                .foregroundStyle(total < 0 ?.red : .green)
                        }
                        Group {
                            Text("Total Basis cost")
                            Text("$\(totalBasis as NSDecimalNumber, formatter: currencyFormatter)")
                                .foregroundStyle(total < 0 ?.red : .green)
                        }
                        Group {
                            Text("Total Value")
                            Text("$\(totalValue as NSDecimalNumber, formatter: currencyFormatter)")
                                .foregroundStyle(total < 0 ?.red : .green)
                        }
                        Group {
                            Text("")
                            Text("")
                        }
                        Group {
                            Text("Sell")
                            Text("$\(sellTotal as NSDecimalNumber, formatter: currencyFormatter)")
                                .foregroundStyle(total < 0 ?.red : .green)
                        }
                        Group {
                            Text("Buy")
                            Text("$\(buyTotal as NSDecimalNumber, formatter: currencyFormatter)")
                                .foregroundStyle(total < 0 ?.red : .green)
                        }
                    }
                    Spacer()
                }
            }
            .padding(.leading, 15)
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
                acceleratedProfitsTotalBasis = portfolioService.acceleratedProfitsTotalBasis
                breakthroughTotalBasis = portfolioService.breakthroughTotalBasis
                eliteDividendPayersTotalBasis = portfolioService.eliteDividendPayersTotalBasis
                growthInvestorTotalBasis = portfolioService.growthInvestorTotalBasis
                dividendList = portfolioService.eliteDividendPayersDividendList
                totalDividend = portfolioService.computeDividendTotal(list: dividendList)
                buyTotal = portfolioService.buyTotal
                sellTotal = portfolioService.sellTotal
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
            .onReceive(portfolioService.$buyTotal) { total in
                buyTotal = total
                computeTotal()
            }
            .onReceive(portfolioService.$sellTotal) { total in
                sellTotal = total
                computeTotal()
            }
            .onReceive(portfolioService.$acceleratedProfitsTotalBasis) { total in
                acceleratedProfitsTotalBasis = total
                computeTotal()
            }
            .onReceive(portfolioService.$breakthroughTotalBasis) { total in
                breakthroughTotalBasis = total
                computeTotal()
            }
            .onReceive(portfolioService.$eliteDividendPayersTotalBasis) { total in
                eliteDividendPayersTotalBasis = total
                computeTotal()
            }
            .onReceive(portfolioService.$growthInvestorTotalBasis) { total in
                growthInvestorTotalBasis = total
                computeTotal()
            }
            .onReceive(portfolioService.$eliteDividendPayersDividendList) { list in
                self.dividendList = list
                totalDividend = portfolioService.computeDividendTotal(list: list)
            }
        }
    }
    
    func computeTotal() {
        total = acceleratedProfitsTotal + breakthroughTotal + eliteDividendPayersTotal + growthInvestorTotal + totalDividend
        totalBasis = acceleratedProfitsTotalBasis + breakthroughTotalBasis + eliteDividendPayersTotalBasis + growthInvestorTotalBasis
        totalValue = total + totalBasis
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
