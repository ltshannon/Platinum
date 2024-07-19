//
//  PortfolioService.swift
//  Platinum
//
//  Created by Larry Shannon on 6/20/24.
//

import Foundation
import SwiftUI

enum PortfolioType: String, CaseIterable, Identifiable {
    case acceleratedProfits = "AcceleratedProfits"
    case breakthroughStocks =  "BreakthroughStocks"
    case eliteDividendPayers = "EliteDividendPayers"
    case growthInvestor = "GrowthInvestor"
    
    var id: String { return self.rawValue }
}

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
    @Published var isHidden = true
    @Published var progress = 0.0
    
    func loadPortfolios() {
        Task { @MainActor in
            isHidden = false
            progress = 0.0
            var result = await getPortfolio(listName: .acceleratedProfits)
            acceleratedProfitsList = result.0
            acceleratedProfitsTotal = result.1
            acceleratedProfitsStockList = result.2
            acceleratedProfitsTotalBasis = result.3
            progress = 25
            result = await getPortfolio(listName: .breakthroughStocks)
            breakthroughList = result.0
            breakthroughTotal = result.1
            breakthroughStockList = result.2
            breakthroughTotalBasis = result.3
            progress = 50
            result = await getPortfolio(listName: .eliteDividendPayers)
            self.eliteDividendPayersList = result.0
            self.eliteDividendPayersTotal = result.1
            self.eliteDividendPayersStockList = result.2
            self.eliteDividendPayersTotalBasis = result.3
            self.eliteDividendPayersDividendList = result.4
            progress = 75
            result = await getPortfolio(listName: .growthInvestor)
            growthInvestorList = result.0
            growthInvestorTotal = result.1
            growthInvestorStockList = result.2
            growthInvestorTotalBasis = result.3
            progress = 100
            isHidden = true
        }
    }
    
    func getPortfolio(listName: PortfolioType) async -> ([ItemData], Decimal, [String], Decimal, [DividendDisplayData]) {
        
        await MainActor.run {
            isHidden = false
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
            isHidden = true
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
    
    func getDividend(listName: String, symbol: String) async -> [String] {
        
        return await firebaseService.getDividend(listName: listName, symbol: symbol)
        
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
    
}
