//
//  FirebaseService.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/5/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore

let database = Firestore.firestore()

struct StockItem: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
}

struct PortfolioItem: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var quantity: Int
    var basis: Decimal
}

struct ModelStock: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var AcceleratedProfits: [String]?
    var BreakthroughStocks: [String]?
    var EliteDividendPayers: [String]?
    var GrowthInvestor: [String]?
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
    
    func getPortfolioList(stockList: [String], listName: String) async -> [PortfolioItem] {
        guard let user = Auth.auth().currentUser else {
            return []
        }
        
        var portfolioItems: [PortfolioItem] = []
        for item in stockList {
            do {
                let querySnapshot = try await database.collection("users").document(user.uid).collection(listName).document(item).getDocument()
                if querySnapshot.exists {
                    let data = try querySnapshot.data(as: PortfolioItem.self)
                    portfolioItems.append(data)
                }
            }
            catch {
                debugPrint("🧨", "Error reading stock items: \(error.localizedDescription)")
            }
        }
        return portfolioItems
    }
    
    func getStockList(listName: String) async -> [String] {
        var items: [String] = []
        
        guard let user = Auth.auth().currentUser else {
            return []
        }
        do {
            let querySnapshot = try await database.collection("users").document(user.uid).collection(listName).getDocuments()
            
            for document in querySnapshot.documents {
                let item = try document.data(as: StockItem.self)
                if let symbol = item.id {
                    if symbol.count <= 4 {
                        items.append(symbol)
                    }
                }
            }
        }
        catch {
            debugPrint("🧨", "Error reading getStockList: \(error.localizedDescription)")
        }
        return items

    }
    
    func getModelStockList(listName: PortfolioType) async -> [String] {
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
                    default:
                        items = []
                    }
                }
            } else {
                debugPrint("🧨", "Error reading getModelStockList Document does not exist")
            }
        } catch {
            debugPrint("🧨", "Error reading getModelStockList \(error.localizedDescription)")
        }
        return items

    }
    
    func addItem(listName: String, symbol: String, quantity: Int, basis: Decimal) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        let temp = NSDecimalNumber(decimal: basis)
        let value = [
            "quantity": quantity,
            "basis": temp
        ] as [String : Any]
        do {
            try await database.collection("users").document(user.uid).collection(listName).document(symbol).setData(value)
        } catch {
            debugPrint(String.boom, "addItem: \(error)")
        }
    }
    
    func updateItem(listName: String, symbol: String, originalSymbol: String, quantity: Int, basis: String) async {
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
                try await database.collection("users").document(user.uid).collection(listName).document(originalSymbol).updateData(value)
            } catch {
                debugPrint(String.boom, "updateItem: \(error)")
            }
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
