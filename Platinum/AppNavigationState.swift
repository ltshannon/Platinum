//
//  AppNavigationState.swift
//  Platinum
//
//  Created by Larry Shannon on 7/22/24.
//

import Foundation

struct DividendCreateParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var key: PortfolioType
    var symbol: String
    var dividendDisplayData: [DividendDisplayData]
    
    init(key: PortfolioType, symbol: String, dividendDisplayData: [DividendDisplayData]) {
        self.key = key
        self.symbol = symbol
        self.dividendDisplayData = dividendDisplayData
    }
}

struct StockDetailParameters: Identifiable, Hashable, Encodable {
    var id = UUID().uuidString
    var key: PortfolioType
    var item: ItemData
    
    init(key: PortfolioType, item: ItemData) {
        self.key = key
        self.item = item
    }
}

struct DividendEditParameters: Identifiable, Hashable, Encodable  {
    var id = UUID().uuidString
    var key: PortfolioType
    var item: ItemData
    var dividendDisplayData: DividendDisplayData
    
    init(key: PortfolioType, item: ItemData, dividendDisplayData: DividendDisplayData) {
        self.key = key
        self.item = item
        self.dividendDisplayData = dividendDisplayData
    }
}

enum DividendNavDestination: Hashable {
    case stockDetailView(StockDetailParameters)
    case dividendCreateView(DividendCreateParameters)
    case dividendEditView(DividendEditParameters)
}

class AppNavigationState: ObservableObject {
    @Published var dividendNavigation: [DividendNavDestination] = []
 
    func stockDetailView(parameters: StockDetailParameters) {
        dividendNavigation.append(DividendNavDestination.stockDetailView(parameters))
    }
    
    func dividendEditView(parameters: DividendEditParameters) {
        dividendNavigation.append(DividendNavDestination.dividendEditView(parameters))
    }
    
}
