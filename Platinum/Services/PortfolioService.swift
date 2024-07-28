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
    
    var id: String { return self.rawValue }
}

@MainActor
class PortfolioService: ObservableObject {
    var firebaseService = FirebaseService.shared
    var networkService = NetworkService()
    @Published var acceleratedProfitsList: [ItemData] = []
    @Published var acceleratedProfitsTotal: Decimal = 0
    @Published var acceleratedProfitsTotalBasis: Decimal = 0
    @Published var acceleratedProfitsStockList: [String] = []
    @Published var breakthroughList: [ItemData] = []
    @Published var breakthroughTotal: Decimal = 0
    @Published var breakthroughTotalBasis: Decimal = 0
    @Published var breakthroughStockList: [String] = []
    @Published var eliteDividendPayersList: [ItemData] = []
    @Published var eliteDividendPayersTotal: Decimal = 0
    @Published var eliteDividendPayersTotalBasis: Decimal = 0
    @Published var eliteDividendPayersDividendList: [DividendDisplayData] = []
    @Published var eliteDividendPayersStockList: [String] = []
    @Published var growthInvestorList: [ItemData] = []
    @Published var growthInvestorTotal: Decimal = 0
    @Published var growthInvestorTotalBasis: Decimal = 0
    @Published var growthInvestorStockList: [String] = []
    @Published var stockList: [String] = []
    @Published var showingProgress = false
    @Published var progress = 0.0
    
    func loadPortfolios() {
        Task { @MainActor in
            showingProgress = true
            progress = 0.0
            async let result1 = getPortfolio(listName: .acceleratedProfits)
            async let result2 = getPortfolio(listName: .breakthroughStocks)
            async let result3 = getPortfolio(listName: .eliteDividendPayers)
            async let result4 = getPortfolio(listName: .growthInvestor)
            acceleratedProfitsList = await result1.0
            acceleratedProfitsTotal = await result1.1
            acceleratedProfitsStockList = await result1.2
            acceleratedProfitsTotalBasis = await result1.3
            progress = 25
            breakthroughList = await result2.0
            breakthroughTotal = await result2.1
            breakthroughStockList = await result2.2
            breakthroughTotalBasis = await result2.3
            progress = 50
            self.eliteDividendPayersList = await result3.0
            self.eliteDividendPayersTotal = await result3.1
            self.eliteDividendPayersStockList = await result3.2
            self.eliteDividendPayersTotalBasis = await result3.3
            self.eliteDividendPayersDividendList = await result3.4
            progress = 75
            growthInvestorList = await result4.0
            growthInvestorTotal = await result4.1
            growthInvestorStockList = await result4.2
            growthInvestorTotalBasis = await result4.3
            progress = 100
            showingProgress = false
        }
    }
    
    func getPortfolio(listName: PortfolioType) async -> ([ItemData], Decimal, [String], Decimal, [DividendDisplayData]) {
        
        await MainActor.run {
//            showingProgress = true
        }
        let stockList = await firebaseService.getStockList(listName: listName.rawValue)
        let data = await firebaseService.getPortfolioList(stockList: stockList, listName: listName)
        var items: [ItemData] = []
        for item in data {
            let temp = ItemData(symbol: item.id ?? "NA", basis: item.basis, price: 0, gainLose: 0, quantity: item.quantity, dividend: item.dividend)
            items.append(temp)
        }
        
        var total: Decimal = 0
        var totalBasis: Decimal = 0
        var dividendList: [DividendDisplayData] = []
        let string: String = stockList.joined(separator: ",")
        let stockData = await networkService.fetch(tickers: string)
        for item in stockData {
            if let row = items.firstIndex(where: { $0.symbol == item.id }) {
                items[row].price = Decimal(Double(item.price))
                let gainLose = Decimal(items[row].quantity) * (Decimal(Double(item.price)) - items[row].basis)
                items[row].gainLose = gainLose
                total += gainLose
                totalBasis += items[row].basis * Decimal(items[row].quantity)
                if listName == .eliteDividendPayers, let dividends = items[row].dividend {
                    let _ = dividends.map {
                        dividendList.append(buildDividendList(array: $0, symbol: item.id))
                    }
                }
            }
        }
        
        let modelStock = await firebaseService.getModelStockList(listName: listName)
        await MainActor.run {
            self.stockList = modelStock.sorted()
//            showingProgress = false
        }
        return (items, total, modelStock, totalBasis, dividendList)
    }
    
    func addStock(listName: String, item: ItemData) async {
        
        await firebaseService.addItem(listName: listName, symbol: item.symbol, quantity: item.quantity, basis: item.basis)
    }
    
    func updateStock(listName: String, symbol: String, originalSymbol: String, quantity: Int, basis: String) async {
        
        await firebaseService.updateItem(listName: listName, symbol: symbol, originalSymbol: originalSymbol, quantity: quantity, basis: basis)
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
        }
        let items = list.filter { $0.symbol == symbol }
        if let item = items.first {
            return item.basis
        }
        return nil
    }
    
}
