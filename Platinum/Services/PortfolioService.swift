//
//  PortfolioService.swift
//  Platinum
//
//  Created by Larry Shannon on 6/20/24.
//

import Foundation
import SwiftUI

class PortfolioService: ObservableObject {
    var firebaseService = FirebaseService.shared
    var networkService = NetworkService()
    
    func getPortfolio(listName: String) async -> ([ItemData], Decimal) {

        let stockList = await firebaseService.getStockList(listName: listName)
        let data = await firebaseService.getPortfolioList(stockList: stockList, listName: listName)
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
        
        return (items, total)
    }
    
    func addStock(listName: String, item: ItemData) async {
        
        await firebaseService.addItem(listName: listName, symbol: item.symbol, quantity: item.quantity, basis: item.basis)
        
    }
    
    func updateStock(listName: String, symbol: String, quantity: Int, basis: String) async {
        
        await firebaseService.updateItem(listName: listName, symbol: symbol, quantity: quantity, basis: basis)
        
    }
    
    func deleteStock(listName: String, symbol: String) async {
        
        await firebaseService.deleteItem(listName: listName, symbol: symbol)
        
    }
    
}
