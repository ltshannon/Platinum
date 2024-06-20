//
//  DataModel.swift
//  MyTasks
//
//  Created by Larry Shannon on 2/25/24.
//

import SwiftUI

struct ItemData: Identifiable, Encodable, Decodable, Hashable {
    var id: String = UUID().uuidString
    var symbol: String
    var basis: Decimal
    var price: Decimal
    var gainLose: Decimal
    var quantity: Int
}

class DataModel: ObservableObject {
    @Published var items: [ItemData] = []
    
    func restore(key: String) async -> [ItemData] {
        if UserDefaults.standard.object(forKey: key) == nil {
            return []
        }
        let json = UserDefaults.standard.string(forKey: key) ?? "{}"
        let jsonDecoder = JSONDecoder()
        guard let jsonData = json.data(using: .utf8) else {
            return []
        }
        do {
            let temp: [ItemData] = try jsonDecoder.decode([ItemData].self, from: jsonData)
            return temp
        } catch {
            debugPrint("🧨", "updateItemsForMoreItems: \(error)")
        }
        return []
    }
    
    func save(key: String, item: ItemData) {
        Task {
            var items = await restore(key: key)
            items.append(item)
            saveToStorage(key: key, item: items)
        }
    }
    
    func saveChangedList(key: String, items: [ItemData]) {
        saveToStorage(key: key, item: items)
    }
    
    func saveToStorage(key: String, item: [ItemData]) {
        do {
            let jsonEncoder = JSONEncoder()
            let jsonData = try jsonEncoder.encode(item)
            let json = String(data: jsonData, encoding: .utf8) ?? "{}"
            let userDefaults = UserDefaults.standard
            userDefaults.set(json, forKey: key)
            userDefaults.synchronize()
        } catch {
            debugPrint("🧨", "updateItemsForMoreItems: \(error)")
        }
    }
    
}

