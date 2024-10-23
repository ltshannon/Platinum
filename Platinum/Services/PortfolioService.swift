//
//  PortfolioService.swift
//  Platinum
//
//  Created by Larry Shannon on 6/20/24.
//

import Foundation
import SwiftUI

enum PortfolioType: String, CaseIterable, Identifiable, Encodable {
    case acceleratedProfits = "AcceleratedProfits"
    case breakthroughStocks =  "BreakthroughStocks"
    case eliteDividendPayers = "EliteDividendPayers"
    case growthInvestor = "GrowthInvestor"
    case buy = "Buy"
    case sell = "Sell"
    
    var id: String { return self.rawValue }
}

enum GrowthClubPortfolio: String, CaseIterable, Identifiable, Encodable {
    case accelerated = "Accelerated"
    case breakthrough = "Breakthrough"
    case dividend = "Dividend"
    case growth = "Growth"
    case buy = "Buy"
    case sell = "Sell"
    
    var id: String { return self.rawValue }
}

@MainActor
class PortfolioService: ObservableObject {
    var firebaseService = FirebaseService.shared
    var networkService = NetworkService()
    @Published var acceleratedProfitsList: [ItemData] = []
    @Published var acceleratedProfitsTotal: Decimal = 0
    @Published var acceleratedProfitsTotalPercent: Decimal = 0
    @Published var acceleratedProfitsTotalBasis: Decimal = 0
    @Published var acceleratedProfitsStockList: [String] = []
    @Published var breakthroughList: [ItemData] = []
    @Published var breakthroughTotal: Decimal = 0
    @Published var breakthroughTotalPercent: Decimal = 0
    @Published var breakthroughTotalBasis: Decimal = 0
    @Published var breakthroughStockList: [String] = []
    @Published var eliteDividendPayersList: [ItemData] = []
    @Published var eliteDividendPayersTotal: Decimal = 0
    @Published var eliteDividendPayersTotalPercent: Decimal = 0
    @Published var eliteDividendPayersTotalBasis: Decimal = 0
    @Published var eliteDividendPayersDividendList: [DividendDisplayData] = []
    @Published var eliteDividendPayersStockList: [String] = []
    @Published var growthInvestorList: [ItemData] = []
    @Published var growthInvestorTotal: Decimal = 0
    @Published var growthInvestorTotalPercent: Decimal = 0
    @Published var growthInvestorTotalBasis: Decimal = 0
    @Published var growthInvestorStockList: [String] = []
    @Published var buyList: [ItemData] = []
    @Published var buyTotal: Decimal = 0
    @Published var buyTotalBasis: Decimal = 0
    @Published var buyTotalPercent: Decimal = 0
    @Published var buyStockList: [String] = []
    @Published var sellList: [ItemData] = []
    @Published var sellTotal: Decimal = 0
    @Published var sellTotalPercent: Decimal = 0
    @Published var sellTotalBasis: Decimal = 0
    @Published var sellStockList: [String] = []
    @Published var stockList: [String] = []
    @Published var showingProgress = false
    
    func loadPortfolios() {
        Task { @MainActor in
            showingProgress = true
            async let result1 = getPortfolio(listName: .acceleratedProfits)
            async let result2 = getPortfolio(listName: .breakthroughStocks)
            async let result3 = getPortfolio(listName: .eliteDividendPayers)
            async let result4 = getPortfolio(listName: .growthInvestor)
            async let result5 = getPortfolio(listName: .buy)
            async let result6 = getPortfolio(listName: .sell)
            acceleratedProfitsList = await result1.0
            acceleratedProfitsTotal = await result1.1
            acceleratedProfitsStockList = await result1.2
            acceleratedProfitsTotalBasis = await result1.3
            acceleratedProfitsTotalPercent = await result1.5
            breakthroughList = await result2.0
            breakthroughTotal = await result2.1
            breakthroughStockList = await result2.2
            breakthroughTotalBasis = await result2.3
            breakthroughTotalPercent = await result2.5
            eliteDividendPayersList = await result3.0
            eliteDividendPayersTotal = await result3.1
            eliteDividendPayersStockList = await result3.2
            eliteDividendPayersTotalBasis = await result3.3
            eliteDividendPayersDividendList = await result3.4
            eliteDividendPayersTotalPercent = await result3.5
            growthInvestorList = await result4.0
            growthInvestorTotal = await result4.1
            growthInvestorStockList = await result4.2
            growthInvestorTotalBasis = await result4.3
            growthInvestorTotalPercent = await result4.5
            buyList = await result5.0
            buyTotal = await result5.1
            buyStockList = await result5.2
            buyTotalBasis = await result5.3
            buyTotalPercent = await result5.5
            sellList = await result6.0
            sellTotal = await result6.1
            sellStockList = await result6.2
            sellTotalBasis = await result6.3
            sellTotalPercent = await result6.5
            showingProgress = false
        }
    }
    
    func getPortfolio(listName: PortfolioType, showSold: Bool = false) async -> ([ItemData], Decimal, [String], Decimal, [DividendDisplayData], Decimal) {
        
        let stockList = await firebaseService.getStockList(listName: listName.rawValue)
        let data = await firebaseService.getPortfolioList(stockList: stockList, listName: listName, showSold: showSold)
        var items: [ItemData] = []
        for item in data {
            var value = ""
            if let symbol = item.symbol {
                value = symbol
            } else {
                value = item.id ?? "NA"
            }
            let temp = ItemData(firestoreId: item.id ?? "n/a", symbol: value, basis: item.basis, price: 0, gainLose: 0, percent: 0, quantity: item.quantity, dividend: item.dividend)
            items.append(temp)
        }
        
        var total: Decimal = 0
        var totalBasis: Decimal = 0
        let totalPercent: Decimal = 0
        var dividendList: [DividendDisplayData] = []
        var list: [String] = []
        for item in stockList {
            if let value = item.symbol {
                if list.contains(value) == false {
                    list.append(value)
                }
            } else {
                if let value = item.id, value.count <= 4 {
                    list.append(value)
                }
            }
        }
        let string: String = list.joined(separator: ",")
        let stockData = await networkService.fetch(tickers: string)
        for item in stockData {
            items.indices.forEach { index in
                if item.id == items[index].symbol {
                    items[index].price = Decimal(Double(item.price))
                    let value = Decimal(Double(item.price)) - items[index].basis
                    items[index].percent = value / items[index].basis
                    let gainLose = Decimal(items[index].quantity) * value
                    items[index].gainLose = gainLose
                    total += gainLose
                    totalBasis += items[index].basis * Decimal(items[index].quantity)
                    if listName == .eliteDividendPayers, let dividends = items[index].dividend {
                        let _ = dividends.map {
                            dividendList.append(buildDividendList(array: $0, symbol: item.id))
                        }
                    }
                }
            }
        }
        
        let modelStock = await getSymbolList(listName: listName)
        return (items, total, modelStock, totalBasis, dividendList, totalPercent)
    }
    
    func getSymbolList(listName: PortfolioType) async -> [String] {
        
        let items = await firebaseService.getModelSymbolList(listName: listName)
        await MainActor.run {
            self.stockList = items.sorted()
        }
        return items
    }
    
    func addSymbol(listName: String, symbol: String) async {
        
        await firebaseService.addSymbol(listName: listName, symbol: symbol)
    }
    
    func updateSymbol(listName: String, newSymbol: String, oldSymbol: String) async {
     
        await firebaseService.updateSymbol(listName: listName, oldSymbol: oldSymbol, newSymbol: newSymbol)
    }
    
    func deleteSymbol(listName: String, symbol: String) async {
        
        await firebaseService.deleteSymbol(listName: listName, symbol: symbol)
    }
    
    func addStock(listName: String, item: ItemData) async {
        
        await firebaseService.addItem(listName: listName, symbol: item.symbol, quantity: item.quantity, basis: item.basis)
    }
    
    func updateStock(firestoreId: String, listName: String, symbol: String, originalSymbol: String, quantity: Double, basis: String) async {
        
        await firebaseService.updateItem(firestoreId: firestoreId, listName: listName, symbol: symbol, originalSymbol: originalSymbol, quantity: quantity, basis: basis)
    }
    
    func soldStock(firestoreId: String, listName: String, price: String) async  {
        
        await firebaseService.soldItem(firestoreId: firestoreId, listName: listName, price: price)
    }
    
    func deleteStock(listName: String, symbol: String) async {
        
        await firebaseService.deleteItem(listName: listName, symbol: symbol)
    }
    
    func addDividend(listName: String, symbol: String, dividendDate: Date, dividendAmount: String) async {
        
        await firebaseService.addDividend(listName: listName, symbol: symbol, dividendDate: dividendDate, dividendAmount: dividendAmount)
    }
    
    func getDividend(listName: String, symbol: String) async {
        
        let array = await firebaseService.getDividend(listName: listName, symbol: symbol)
        var data: [DividendDisplayData] = []
        let _ = array.map {
            let value = $0.split(separator: ",")
            if value.count == 2 {
                if let dec = Decimal(string: String(value[1])) {
                    let item = DividendDisplayData(symbol: symbol, date: String(value[0]), price: dec)
                    data.append(item)
                }
            }
        }
        var temp = eliteDividendPayersDividendList.filter { $0.symbol != symbol }
        temp += data
        temp = temp.sorted { $0.symbol < $1.symbol }
        await MainActor.run {
            self.eliteDividendPayersDividendList = temp
        }
    }

    func deleteDividend(listName: String, symbol: String, dividendDisplayData: DividendDisplayData) async {
        await firebaseService.deleteDividend(listName: listName, symbol: symbol, dividendDisplayData: dividendDisplayData)
    }
    
    func updateDividend(listName: String, symbol: String, dividendDisplayData: DividendDisplayData, dividendDate: Date, dividendAmount: String) async {
        
        await firebaseService.updateDividend(listName: listName, symbol: symbol, dividendDisplayData: dividendDisplayData, dividendAmount: dividendAmount, dividendDate: dividendDate)
    }
    
    func buildDividendList(array: String, symbol: String) -> DividendDisplayData {
        var data = DividendDisplayData(date: "", price: 0)
        let value = array.split(separator: ",")
        if value.count == 2 {
            if let dec = Decimal(string: String(value[1])) {
                data = DividendDisplayData(symbol: symbol, date: String(value[0]), price: dec)
            }
        }
        return data
    }
    
    func computeDividendTotal(list: [DividendDisplayData]) -> Decimal {
        var total: Decimal = 0
        let _ = list.map {
            total += $0.price
        }
        return total
    }
    
    func getBasisForStockInPortfilio(portfolioType: PortfolioType, symbol: String) -> Decimal? {
        var list: [ItemData] = []
        switch portfolioType {
        case .acceleratedProfits:
            list = acceleratedProfitsList;
        case .breakthroughStocks:
            list = breakthroughList
        case .eliteDividendPayers:
            list = eliteDividendPayersList
        case.growthInvestor:
            list = growthInvestorList
        case.buy:
            list = buyList
        case.sell:
            list = sellList
        }
        let items = list.filter { $0.symbol == symbol }
        if let item = items.first {
            return item.basis
        }
        return nil
    }
    
}
