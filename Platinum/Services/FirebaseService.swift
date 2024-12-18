//
//  FirebaseService.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/5/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseAuth

let database = Firestore.firestore()

struct StockItem: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var symbol: String?
}

struct PortfolioItem: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var quantity: Double
    var basis: Decimal
    var dividend: [String]?
    var symbol: String?
    var isSold: Bool?
    var price: Decimal?
}

struct ModelStock: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var AcceleratedProfits: [String]?
    var BreakthroughStocks: [String]?
    var EliteDividendPayers: [String]?
    var GrowthInvestor: [String]?
    var Buy: [String]?
    var Sell: [String]?
}

struct DividendDisplayData: Codable, Identifiable, Hashable, Equatable {
    var id = UUID().uuidString
    var symbol = ""
    var date = ""
    var price: Decimal = 0
}

struct DividendPlaceholder: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var dividend: DividendData
}

struct DividendData: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var values: [String]
}

extension DividendData {
    init(snapshot: Dictionary<String, Any>) {
        let item = snapshot["values"] as? [String] ?? []
        values = item
    }
}

struct FirebaseUserInformation: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var displayName: String?
    var email: String?
    var subscription: Bool?
}

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    @AppStorage("profile-url") var profileURL: String = ""
    @Published var user: FirebaseUserInformation = FirebaseUserInformation(id: "", displayName: "", email: "", subscription: false)
    var fmc: String = ""
    var userListener: ListenerRegistration?
    
    func getUser() {
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let listener = database.collection("users").document(user.uid).addSnapshotListener { documentSnapshot, error in

            guard let document = documentSnapshot, let _ = document.data() else {
                print("getUser: Error fetching document: \(user.uid)")
                return
            }
            do {
                let user = try document.data(as: FirebaseUserInformation.self)
                DispatchQueue.main.async {
                    self.user = user
                }
            } catch {
                debugPrint("getUser reading data: \(error.localizedDescription)")
            }

        }
        self.userListener = listener
    }
    
    func createUser(token: String) async {
        
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let data = ["email": user.email ?? "no email",
                "displayName": user.displayName ?? user.uid,
                "fcm": token
               ]
        do {
            try await database.collection("users").document(user.uid).updateData(data)
            debugPrint(String.bell, "users successfully written!")
        } catch {
            debugPrint(String.fatal, "users: Error writing moreLists: \(error)")
            return
        }
    }
    
    func getPortfolioList(stockList: [StockItem], listName: PortfolioType, displayStockState: DisplayStockState) async -> [PortfolioItem] {
        var id: String = ""
        guard let user = Auth.auth().currentUser else {
            return []
        }
        
        var portfolioItems: [PortfolioItem] = []
        for item in stockList {
            do {
                id = item.id ?? "n/a"
                let querySnapshot = try await database.collection("users").document(user.uid).collection(listName.rawValue).document(id).getDocument()
                if querySnapshot.exists {
                    var data = try querySnapshot.data(as: PortfolioItem.self)
                    if displayStockState == .showSoldStocks && data.isSold == nil {
                        continue
                    }
                    if let _ = data.isSold, displayStockState == .showActiveStocks {
                        continue
                    }
                    if let stock = data.symbol {
                        data.symbol = stock
                    } else {
                        data.symbol = data.id ?? "n/a"
                    }
//                    if listName == .eliteDividendPayers {
                        let querySnapshot2 = try await database.collection("users").document(user.uid).collection(listName.rawValue).document(id).collection("dividend").document("dividend").getDocument()
                        if querySnapshot2.exists {
                            let data2 = try querySnapshot2.data(as: DividendData.self)
                            //                        debugPrint("👾", "dividend: \(data2)")
                            data.dividend = data2.values
//                        }
                    }
                    portfolioItems.append(data)
                }
            }
            catch {
                debugPrint("🧨", "id: \(id) listName: \(listName.rawValue) Error reading stock items: \(error.localizedDescription)")
            }
        }
        
        return portfolioItems.sorted(by: { $0.symbol ?? "" < $1.symbol ?? "" })
    }
    
    func getStockList(listName: String) async -> [StockItem] {
        var items: [StockItem] = []
        
        guard let user = Auth.auth().currentUser else {
            return []
        }
        do {
            let querySnapshot = try await database.collection("users").document(user.uid).collection(listName).getDocuments()
            
            for document in querySnapshot.documents {
                var item = try document.data(as: StockItem.self)
                if let _ = item.id {
                    if let symbol = item.symbol {
                        item.symbol = symbol
                    }
                    items.append(item)
                }
            }
        }
        catch {
            debugPrint("🧨", "Error reading getStockList: \(error.localizedDescription)")
        }
        items.sort(by: { $0.id ?? "" < $1.id ?? "" })
        return items

    }
    
    func getModelSymbolList(listName: PortfolioType) async -> [String] {
        var items: [String] = []
        
        let docRef = database.collection("ModelPortfolio").document(listName.rawValue)
        do {
            let document = try await docRef.getDocument()
            if document.exists {
                let data = try document.data(as: ModelStock.self)
                debugPrint("data: \(data.id ?? "no id")")
                if let value = data.id {
                    switch value {
                    case PortfolioType.acceleratedProfits.rawValue:
                        if let values = data.AcceleratedProfits {
                            items = values
                        }
                    case PortfolioType.breakthroughStocks.rawValue:
                        if let values = data.BreakthroughStocks {
                            items = values
                        }
                    case PortfolioType.eliteDividendPayers.rawValue:
                        if let values = data.EliteDividendPayers {
                            items = values
                        }
                    case PortfolioType.growthInvestor.rawValue:
                        if let values = data.GrowthInvestor {
                            items = values
                        }
                    case PortfolioType.buy.rawValue:
                        if let values = data.Buy {
                            items = values
                        }
                    case PortfolioType.sell.rawValue:
                        if let values = data.Sell {
                            items = values
                        }
                    default:
                        items = []
                    }
                }
            } else {
                debugPrint("🧨", "Error reading getModelSymbolList Document does not exist")
            }
        } catch {
            debugPrint("🧨", "Error reading getModelSymbolList \(error.localizedDescription)")
        }
        items.sort()
        return items

    }
    
    func addSymbol(listName: String, symbol: String) async {
        
        do {
            try await database.collection("ModelPortfolio").document(listName).updateData([listName: FieldValue.arrayUnion([symbol])])
        } catch {
            debugPrint(String.boom, "addSymbol failed: \(error)")
        }
        
    }
    
    func updateSymbol(listName: String, oldSymbol: String, newSymbol: String) async {
        
        do {
            try await database.collection("ModelPortfolio").document(listName).updateData([listName: FieldValue.arrayRemove([oldSymbol])])
            try await database.collection("ModelPortfolio").document(listName).updateData([listName: FieldValue.arrayUnion([newSymbol])])
        } catch {
            debugPrint(String.boom, "updateSymbol failed: \(error)")
        }
        
    }
    
    func deleteSymbol(listName: String, symbol: String) async {

        do {
            try await database.collection("ModelPortfolio").document(listName).updateData([listName: FieldValue.arrayRemove([symbol])])
        } catch {
            debugPrint(String.boom, "deleteSymbol failed: \(error)")
        }
        
    }
    
    func addItem(listName: String, symbol: String, quantity: Double, basis: Decimal) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let temp = NSDecimalNumber(decimal: basis)
        let value = [
            "symbol": symbol,
            "quantity": quantity,
            "basis": temp
        ] as [String : Any]
        do {
//            try await database.collection("users").document(user.uid).collection(listName).document(symbol).setData(value)
            try await database.collection("users").document(user.uid).collection(listName).addDocument(data: value)
        } catch {
            debugPrint(String.boom, "addItem: \(error)")
        }
        
    }
    
    func getDividend(listName: String, symbol: String) async -> [String] {
        var returnVal: [String] = []
        
        guard let user = Auth.auth().currentUser else {
            return returnVal
        }
        
        let docRef = database.collection("users").document(user.uid).collection(listName).document(symbol).collection("dividend").document("dividend")
        do {
            let document = try await docRef.getDocument()
            if document.exists {
                let items = DividendData(snapshot: document.data() ?? [:])
                returnVal = items.values
            }
        } catch {
            debugPrint(String.boom, "getDividend: \(error)")
        }
        return returnVal
        
    }
    
    func buildDividendArrayElement(dividendDate: Date, dividendAmount: String) -> [String] {
        
        let formatter1 = DateFormatter()
        formatter1.dateStyle = .short
        var str = formatter1.string(from: dividendDate)
        str += "," + "\(dividendAmount)"
        var array: [String] = []
        array.append(str)
        return array
        
    }
    
    func addDividend(listName: String, symbol: String, dividendDate: Date, dividendAmount: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let array = buildDividendArrayElement(dividendDate: dividendDate, dividendAmount: dividendAmount)
        do {
            try await database.collection("users").document(user.uid).collection(listName).document(symbol).collection("dividend").document("dividend").updateData(["values": FieldValue.arrayUnion(array)])
        } catch {
            do {
                try await database.collection("users").document(user.uid).collection(listName).document(symbol).collection("dividend").document("dividend").setData(["values": FieldValue.arrayUnion(array)])
            } catch {
                debugPrint(String.boom, "addDividend failed: \(error)")
            }
        }
        
    }
    
    func deleteDividend(listName: String, symbol: String, dividendDisplayData: DividendDisplayData) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let str = dividendDisplayData.date + ",\(dividendDisplayData.price)"
        var array: [String] = []
        array.append(str)
        do {
            try await database.collection("users").document(user.uid).collection(listName).document(symbol).collection("dividend").document("dividend").updateData(["values": FieldValue.arrayRemove(array)])
        } catch {
            debugPrint(String.boom, "deleteDividend failed: \(error)")
        }
        
    }
    
    func updateDividend(listName: String, symbol: String, dividendDisplayData: DividendDisplayData, dividendAmount: String, dividendDate: Date) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let str = dividendDisplayData.date + ",\(dividendDisplayData.price)"
        var array: [String] = []
        array.append(str)
        let array2 = buildDividendArrayElement(dividendDate: dividendDate, dividendAmount: dividendAmount)
        do {
            try await database.collection("users").document(user.uid).collection(listName).document(symbol).collection("dividend").document("dividend").updateData(["values": FieldValue.arrayRemove(array)])
            try await database.collection("users").document(user.uid).collection(listName).document(symbol).collection("dividend").document("dividend").updateData(["values": FieldValue.arrayUnion(array2)])
        } catch {
            debugPrint(String.boom, "updateDividend failed: \(error)")
        }
        
    }
    
    func updateItem(firestoreId: String, listName: String, symbol: String, originalSymbol: String, quantity: Double, basis: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var item = basis
        if item.contains("$") {
            item = String(basis.dropFirst())
        }
        let dec = Decimal(string: item) ?? 0
        let temp = NSDecimalNumber(decimal:  dec)
        if symbol != originalSymbol {
            await deleteItem(listName: listName, symbol: originalSymbol)
            await addItem(listName: listName, symbol: symbol, quantity: quantity, basis: dec)
        } else {
            let value = [
                "quantity": quantity,
                "basis": temp
            ] as [String : Any]
            do {
                try await database.collection("users").document(user.uid).collection(listName).document(firestoreId).updateData(value)
            } catch {
                debugPrint(String.boom, "updateItem: \(error)")
            }
        }
        
    }
    
    func soldItem(firestoreId: String, listName: String, price: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let dec = Decimal(string: price) ?? 0
        let value = [
            "price": dec,
            "isSold": true
        ] as [String : Any]
        do {
            try await database.collection("users").document(user.uid).collection(listName).document(firestoreId).updateData(value)
        } catch {
            debugPrint(String.boom, "soldItem: \(error)")
        }
        
    }
    
    func deleteItem(listName: String, symbol: String) async  {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        do {
          try await database.collection("users").document(user.uid).collection(listName).document(symbol).delete()
        } catch {
            debugPrint(String.boom, "deleteItem: \(error)")
        }
        
    }

    func updateAddFCMToUser(token: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        self.fmc = token
        
        let values = [
                        "fcm" : token,
                     ]
        do {
            try await database.collection("users").document(currentUid).updateData(values)
        } catch {
            debugPrint("🧨", "updateAddFCMToUser: \(error)")
        }
        
    }

    func updateAddUserProfileImage(url: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let value = [
            "profileImage" : url
        ]
        do {
            try await database.collection("users").document(currentUid).updateData(value)
        } catch {
            debugPrint(String.boom, "updateAddUserProfileImage: \(error)")
        }
        
    }

}
