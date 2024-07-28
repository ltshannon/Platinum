//
//  NetworkService.swift
//  Platinum
//
//  Created by Larry Shannon on 6/12/24.
//

import Foundation

struct StockData: Identifiable, Codable, Hashable {
    var id: String
    var price: Float
    
    enum CodingKeys: String, CodingKey {
        case id = "symbol"
        case price
    }
}

class NetworkService: ObservableObject {
    @Published var stockData: [StockData] = []
    
    func fetch(tickers: String) async -> [StockData] {
        do {
            if let url = URL(string: "https://financialmodelingprep.com/api/v3/quote-short/" + tickers + "?apikey=w5aSHK4lDmUdz6wSbKtSlcCgL1ckI12Q") {
                let session = URLSession(configuration: .default)
                let response = try await session.data(from: url)
                let data = try JSONDecoder().decode([StockData].self, from: response.0)
//                debugPrint("StockData: \(data)")
                return data
            }
        }
        catch {
            debugPrint("NetworkService error: \(error)")
        }
        return []
    }
    
}
