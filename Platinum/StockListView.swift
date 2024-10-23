//
//  ContentView.swift
//  MyTasks
//
//  Created by Larry Shannon on 2/25/24.
//

import SwiftUI

let currencyFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencySymbol = ""
    return formatter
}()

let percentFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .percent
    formatter.currencySymbol = ""
    return formatter
}()

struct StockListView: View {
    @EnvironmentObject var portfolioService: PortfolioService
    @EnvironmentObject var appNavigationState: AppNavigationState
    @StateObject var settingsService = SettingsService.shared
    var key: PortfolioType
    @StateObject var networkService = NetworkService()
    @State var showingSheet: Bool = false
    @State var firstTime = true
    @State var item: ItemData = ItemData(firestoreId: "", symbol: "Noname", basis: 0, price: 0, gainLose: 0, percent: 0, quantity: 0, isSold: false)
    @State var total: Decimal = 0
    @State var totalBasis: Decimal = 0
    @State var totalPercent: Decimal = 0
    @State var totalDividend: Decimal = 0
    @State var items: [ItemData] = []
    @State var stockList: [String] = []
    @State var dividendList: [DividendDisplayData] = []
    @State var isPercent: Bool = false
    let columns: [GridItem] = [
                                GridItem(.fixed(55), spacing: 1),
                                GridItem(.fixed(45), spacing: 1),
                                GridItem(.fixed(80), spacing: 1),
                                GridItem(.fixed(75), spacing: 1),
                                GridItem(.fixed(80), spacing: 1),
                                GridItem(.fixed(25), spacing: 1)
    ]

    var body: some View {
        ScrollView {
            if portfolioService.showingProgress {
                ProgressView("Loading...")
                    .progressViewStyle(CircularProgressViewStyle(tint: Color.blue))
                    .padding(.trailing, 30)
            }
            LazyVGrid(columns: columns, alignment: .leading) {
                Group {
                    Text("Sym")
                    Text("Qty")
                    Text("Basis $")
                    Text("Price $")
                    Button {
                        isPercent.toggle()
                    } label: {
                        Text(isPercent ? "Gain %" : "Gain $")
                            .underline()
                    }
                    Text("")
                }
                .underline()
                ForEach(items, id: \.id) { item in
                    Text("\(item.symbol)")
                        .foregroundStyle(item.isSold ? .orange : .primary)
                    Text(item.quantity.truncatingRemainder(dividingBy: 1) > 0 ? "\(item.quantity, specifier: "%.2f")" : "\(item.quantity, specifier: "%.0f")")
                    Text("\(item.basis as NSDecimalNumber, formatter: currencyFormatter)")
                    Text("\(item.price as NSDecimalNumber, formatter: currencyFormatter)")
                    if isPercent {
                        Text("\(abs(item.percent) as NSDecimalNumber, formatter: percentFormatter)")
                            .foregroundStyle(item.gainLose < 0 ?.red : .green)
                    } else {
                        Text("\(abs(item.gainLose) as NSDecimalNumber, formatter: currencyFormatter)")
                            .foregroundStyle(item.gainLose < 0 ?.red : .green)
                    }
                    Button {
                        let paramters = StockDetailParameters(key: key, item: item)
                        appNavigationState.stockDetailView(parameters: paramters)
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
                Group {
                    Text("")
                    Text("")
                    Text("---------")
                    Text("")
                    Text("---------")
                    Text("")
                }
                Group {
                    Text("Total")
                    Text("")
                    Text("\(totalBasis as NSDecimalNumber, formatter: currencyFormatter)")
                    Text("")
                    Text("\(total as NSDecimalNumber, formatter: currencyFormatter)")
                        .foregroundStyle(total < 0 ? .red : .green)
                    Text("")
                }
                if key == .eliteDividendPayers {
                    Group {
                        Group {
                            Text("")
                            Text("")
                            Text("")
                            Text("")
                            Text("")
                            Text("")
                        }
                        Group {
                            Text("")
                            Text("")
                            Text("Dividends")
                            Text("")
                            Text("")
                            Text("")
                        }
                        Group {
                            Text("")
                            Text("")
                            Text("----------")
                            Text("")
                            Text("")
                            Text("")
                        }
                        ForEach(dividendList, id: \.id) { dividend in
                            Text("")
                            Text("")
                            Text("\(dividend.symbol)")
                            Text("\(dividend.date)")
                            Text("\(dividend.price as NSDecimalNumber, formatter: currencyFormatter)")
                            Button {
                                let parameters = DividendEditParameters(key: key, item: item, dividendDisplayData: dividend)
                                appNavigationState.dividendEditView(parameters: parameters)
                            } label: {
                                Image(systemName: "pencil")
                            }
                        }
                        Group {
                            Text("")
                            Text("")
                            Text("")
                            Text("")
                            Text("---------")
                            Text("")
                        }
                        Group {
                            Text("Total")
                            Text("")
                            Text("")
                            Text("")
                            Text("\(totalDividend as NSDecimalNumber, formatter: currencyFormatter)")
                            Text("")
                        }
                    }
                }
            }
        }
        .refreshable {
            pullToRefresh()
        }
        .padding([.leading, .trailing], 5)
        Spacer()
        Button {
            showingSheet = true
        } label: {
            VStack(alignment: .center) {
                Image(systemName: "plus.circle")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                Text("Add Stock")
            }
        }
        Spacer()
        .onAppear {
            switch key {
            case .acceleratedProfits:
                items = portfolioService.acceleratedProfitsList
            case .breakthroughStocks:
                items = portfolioService.breakthroughList
            case .eliteDividendPayers:
                items = portfolioService.eliteDividendPayersList
                dividendList = portfolioService.eliteDividendPayersDividendList
                totalDividend = portfolioService.computeDividendTotal(list: dividendList)
            case .growthInvestor:
                items = portfolioService.growthInvestorList
            case .buy:
                items = portfolioService.buyList
            case .sell:
                items = portfolioService.sellList
            }
        }
        .onChange(of: settingsService.isShowSoldStocks) { oldValue, newValue in
            pullToRefresh()
        }
        .onReceive(portfolioService.$eliteDividendPayersList) { list in
            if key == .eliteDividendPayers {
                self.items = list
            }
        }
        .onReceive(portfolioService.$eliteDividendPayersTotal) { total in
            if key == .eliteDividendPayers {
                self.total = total
            }
        }
        .onReceive(portfolioService.$eliteDividendPayersTotalPercent) { percent in
            if key == .eliteDividendPayers {
                self.totalPercent = percent
            }
        }
        .onReceive(portfolioService.$eliteDividendPayersTotalBasis) { total in
            if key == .eliteDividendPayers {
                self.totalBasis = total
            }
        }
        .onReceive(portfolioService.$eliteDividendPayersDividendList) { list in
            if key == .eliteDividendPayers {
                self.dividendList = list
                totalDividend = portfolioService.computeDividendTotal(list: list)
            }
        }
        .onReceive(portfolioService.$eliteDividendPayersStockList) { stockList in
            if key == .eliteDividendPayers {
                self.stockList = stockList
            }
        }
        .onReceive(portfolioService.$acceleratedProfitsList) { list in
            if key == .acceleratedProfits {
                self.items = list
            }
        }
        .onReceive(portfolioService.$acceleratedProfitsTotal) { total in
            if key == .acceleratedProfits {
                self.total = total
            }
        }
        .onReceive(portfolioService.$acceleratedProfitsTotalBasis) { total in
            if key == .acceleratedProfits {
                self.totalBasis = total
            }
        }
        .onReceive(portfolioService.$acceleratedProfitsTotalPercent) { total in
            if key == .acceleratedProfits {
                self.totalPercent = total
            }
        }
        .onReceive(portfolioService.$acceleratedProfitsStockList) { stockList in
            if key == .acceleratedProfits {
                self.stockList = stockList
            }
        }
        .onReceive(portfolioService.$breakthroughList) { list in
            if key == .breakthroughStocks {
                self.items = list
            }
        }
        .onReceive(portfolioService.$breakthroughTotal) { total in
            if key == .breakthroughStocks {
                self.total = total
            }
        }
        .onReceive(portfolioService.$breakthroughTotalBasis) { total in
            if key == .breakthroughStocks {
                self.totalBasis = total
            }
        }
        .onReceive(portfolioService.$breakthroughTotalPercent) { total in
            if key == .breakthroughStocks {
                self.totalPercent = total
            }
        }
        .onReceive(portfolioService.$breakthroughStockList) { stockList in
            if key == .breakthroughStocks {
                self.stockList = stockList
            }
        }
        .onReceive(portfolioService.$growthInvestorList) { list in
            if key == .growthInvestor {
                self.items = list
            }
        }
        .onReceive(portfolioService.$growthInvestorTotal) { total in
            if key == .growthInvestor {
                self.total = total
            }
        }
        .onReceive(portfolioService.$growthInvestorTotalBasis) { total in
            if key == .growthInvestor {
                self.totalBasis = total
            }
        }
        .onReceive(portfolioService.$growthInvestorTotalPercent) { total in
            if key == .growthInvestor {
                self.totalPercent = total
            }
        }
        .onReceive(portfolioService.$growthInvestorStockList) { stockList in
            if key == .growthInvestor {
                self.stockList = stockList
            }
        }
        .onReceive(portfolioService.$buyList) { items in
            if key == .buy {
                self.items = items
            }
        }
        .onReceive(portfolioService.$buyTotal) { total in
            if key == .buy {
                self.total = total
            }
        }
        .onReceive(portfolioService.$buyTotalBasis) { total in
            if key == .buy {
                self.totalBasis = total
            }
        }
        .onReceive(portfolioService.$buyTotalPercent) { total in
            if key == .buy {
                self.totalPercent = total
            }
        }
        .onReceive(portfolioService.$buyStockList) { stockList in
            if key == .buy {
                self.stockList = stockList
            }
        }
        .onReceive(portfolioService.$sellList) { items in
            if key == .sell {
                self.items = items
            }
        }
        .onReceive(portfolioService.$sellTotal) { total in
            if key == .sell {
                self.total = total
            }
        }
        .onReceive(portfolioService.$sellTotalPercent) { total in
            if key == .sell {
                self.totalPercent = total
            }
        }
        .onReceive(portfolioService.$sellTotalBasis) { total in
            if key == .sell {
                self.totalBasis = total
            }
        }
        .onReceive(portfolioService.$sellStockList) { stockList in
            if key == .sell {
                self.stockList = stockList
            }
        }
        .fullScreenCover(isPresented: $showingSheet, onDismiss: didDismiss) {
            AddingNewStockView(key: key, stockList: stockList)
        }
    }
    
    func pullToRefresh() {
        refreshStocks()
    }
    
    func refreshStocks() {
        Task {
            await MainActor.run {
                portfolioService.showingProgress = true
            }
            let result = await portfolioService.getPortfolio(listName: key)
            await MainActor.run {
                items = result.0
                total = result.1
                stockList = result.2
                totalBasis = result.3
                dividendList = result.4
                totalPercent = result.5
                totalDividend = portfolioService.computeDividendTotal(list: result.4)
                switch key {
                case .acceleratedProfits:
                    portfolioService.acceleratedProfitsList = result.0
                    portfolioService.acceleratedProfitsTotal = result.1
                    portfolioService.acceleratedProfitsStockList = result.2
                    portfolioService.acceleratedProfitsTotalPercent = result.5
                case .breakthroughStocks:
                    portfolioService.breakthroughList = result.0
                    portfolioService.breakthroughTotal = result.1
                    portfolioService.breakthroughStockList = result.2
                    portfolioService.breakthroughTotalPercent = result.5
                case .eliteDividendPayers:
                    portfolioService.eliteDividendPayersList = result.0
                    portfolioService.eliteDividendPayersTotal = result.1
                    portfolioService.eliteDividendPayersStockList = result.2
                    portfolioService.eliteDividendPayersTotalBasis = result.3
                    portfolioService.eliteDividendPayersDividendList = result.4
                    portfolioService.eliteDividendPayersTotalPercent = result.5
                case .growthInvestor:
                    portfolioService.growthInvestorList = result.0
                    portfolioService.growthInvestorTotal = result.1
                    portfolioService.growthInvestorStockList = result.2
                    portfolioService.growthInvestorTotalPercent = result.5
                case .buy:
                    portfolioService.buyList = result.0
                    portfolioService.buyTotal = result.1
                    portfolioService.buyStockList = result.2
                    portfolioService.buyTotalPercent = result.5
                case .sell:
                    portfolioService.sellList = result.0
                    portfolioService.sellTotal = result.1
                    portfolioService.sellStockList = result.2
                    portfolioService.sellTotalPercent = result.5
                }
                portfolioService.showingProgress = false
            }
        }
    }
    
    func didDismiss() {
        refreshStocks()
    }
    
}

#Preview {
    StockListView(key: .acceleratedProfits)
}
