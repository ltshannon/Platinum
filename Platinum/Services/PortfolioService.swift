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
    @Published var acceleratedProfitsStockList: [String] = []
    @Published var breakthroughList: [ItemData] = []
    @Published var breakthroughTotal: Decimal = 0
    @Published var breakthroughStockList: [String] = []
    @Published var eliteDividendPayersList: [ItemData] = []
    @Published var eliteDividendPayersTotal: Decimal = 0
    @Published var eliteDividendPayersStockList: [String] = []
    @Published var growthInvestorList: [ItemData] = []
    @Published var growthInvestorTotal: Decimal = 0
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
            progress = 25
            result = await getPortfolio(listName: .breakthroughStocks)
            breakthroughList = result.0
            breakthroughTotal = result.1
            breakthroughStockList = result.2
            progress = 50
            result = await getPortfolio(listName: .eliteDividendPayers)
            self.eliteDividendPayersList = result.0
            self.eliteDividendPayersTotal = result.1
            self.eliteDividendPayersStockList = result.2
            progress = 75
            result = await getPortfolio(listName: .growthInvestor)
            growthInvestorList = result.0
            growthInvestorTotal = result.1
            growthInvestorStockList = result.2
            progress = 100
            isHidden = true
        }
    }
    
    func getPortfolio(listName: PortfolioType) async -> ([ItemData], Decimal, [String]) {
        
        await MainActor.run {
            isHidden = false
        }
        let stockList = await firebaseService.getStockList(listName: listName.rawValue)
        let data = await firebaseService.getPortfolioList(stockList: stockList, listName: listName.rawValue)
        var items: [ItemData] = []
        for item in data {
            let temp = ItemData(symbol: item.id ?? "NA", basis: item.basis, price: 0, gainLose: 0, quantity: item.quantity)
            items.append(temp)
        }
        
        var total: Decimal = 0
        let string: String = stockList.joined(separator: ",")
        let stockData = await networkService.fetch(tickers: string)
        for item in stockData {
            if let row = items.firstIndex(where: { $0.symbol == item.id }) {
                items[row].price = Decimal(Double(item.price))
                let gainLose = Decimal(items[row].quantity) * (Decimal(Double(item.price)) - items[row].basis)
                items[row].gainLose = gainLose
                total += gainLose
            }
        }
        
        let modelStock = await firebaseService.getModelStockList(listName: listName)
        await MainActor.run {
            self.stockList = modelStock.sorted()
            isHidden = true
        }
        return (items, total, modelStock)
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
    
}
