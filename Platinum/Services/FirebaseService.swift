//
//  FirebaseService.swift
//  SwipeAction
//
//  Created by Larry Shannon on 2/5/24.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import FirebaseFunctions
import FirebaseFirestoreSwift

let database = Firestore.firestore()

struct UserInformation: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var displayName: String?
    var email: String?
    var fcm: String?
}

struct StockItem: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
}

struct PortfolioItem: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var quantity: Int
    var basis: Decimal
}

enum ListItemType: String {
    case currentItems = "currentItems"
    case defaultItems = "defaultItems"
    case sharedItems = "sharedItems"
}

struct NameList: Codable, Identifiable, Hashable {
    var id: String
    var name: String
    var imageName = "circle"
}

struct MoreLists: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    var listNames: [NameList] = []
    var lists: [[String: [NameList]]] = [[:]]
}

extension MoreLists {
    init(snapshot: Dictionary<String, Any>) {
        let items = snapshot["xxxLists"] as? [String] ?? []
        var nameLists: [NameList] = []
        let _ = items.map {
            let nameItem = NameList(id: UUID().uuidString, name: $0)
            nameLists.append(nameItem)
        }
        listNames = nameLists
        var temp: [[String: [NameList]]] = []
        for item in items {
            let list = snapshot[item] as? [String] ?? []
            var nameLists: [NameList] = []
            for element in list {
                let nameItem = NameList(id: UUID().uuidString, name: element)
                nameLists.append(nameItem)
            }
            temp.append([item: nameLists])
        }
        lists = temp
    }
}

class FirebaseService: ObservableObject {
    static let shared = FirebaseService()
    @AppStorage("profile-url") var profileURL: String = ""
    @Published var portfolio: [PortfolioItem] = []
    @Published var sharingUsers: [UserInformation] = []
    @Published var moreLists: MoreLists = MoreLists()
    var moreListsListener: ListenerRegistration?
    var userListener: ListenerRegistration?
    var fmc: String = ""
    
    
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
    
    func updateItem(listName: String, symbol: String, quantity: Int, basis: String) async {
        guard let user = Auth.auth().currentUser else {
            return
        }
        
        var item = basis
        if item.contains("$") {
            item = String(basis.dropFirst())
        }
        let dec = Decimal(string: item) ?? 0
        debugPrint("dec: \(dec)")
        let temp = NSDecimalNumber(decimal:  dec)
        let value = [
            "quantity": quantity,
            "basis": temp
        ] as [String : Any]
        do {
            try await database.collection("users").document(user.uid).collection(listName).document(symbol).updateData(value)
        } catch {
            debugPrint(String.boom, "updateItem: \(error)")
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

/*
    func getMoreLists(docID: String, collectionName: String) {
        
        let moreLists = database.collection(collectionName).document(docID).addSnapshotListener { documentSnapshot, error in
                
            guard let document = documentSnapshot, let _ = document.data() else {
                print("setupListenerForMessageThread: Error fetching document: \(docID)")
                return
            }
            let lists = MoreLists(snapshot: document.data() ?? [:])
            DispatchQueue.main.async {
                self.moreLists = lists
            }
        }
            moreListsListener = moreLists
    }
    
    func getListsForUser(userId: String, collectionName: String) async throws -> MoreLists? {
        
        let document = try await database.collection(collectionName).document(userId).getDocument()
        if document.exists {
            let lists = MoreLists(snapshot: document.data() ?? [:])
            return lists
        }
        return nil

    }
    
    func getUserDataForWidget() async -> UserInformation? {
        
        guard let user = Auth.auth().currentUser else {
            return nil
        }
        do {
            let document = try await database.collection("users").document(user.uid).getDocument()
            if document.exists {
                let data = try document.data(as: UserInformation.self)
                return data
            }
            return nil
        } catch {
            debugPrint(String.boom, "getUserDataForWidget failed: \(error.localizedDescription)")
        }
        return nil
    }
    
    func getSharedUsers() async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        do {
            let querySnapshot = try await database.collection("users").whereField("sharedWith", arrayContains: currentUid).getDocuments()
         
            DispatchQueue.main.async {
                var items: [UserInformation] = []
                for document in querySnapshot.documents {
                    do {
                        let user = try document.data(as: UserInformation.self)
                        items.append(user)
                    }
                    catch {
                        debugPrint("🧨", "getSharedUsers error: \(error.localizedDescription)")
                    }
                }

                self.sharingUsers = items
            }
        } catch {
            debugPrint("🧨", "getSharedUsers: \(error)")
        }

    }
*/
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
/*
    func restoreDefault(items: [String]) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let value = [
                    ListItemType.currentItems.rawValue : items
                    ]
        do {
            try await database.collection("users").document(currentUid).updateData(value)
        } catch {
            debugPrint(String.boom, "setDefaultToCurrent: \(error)")
        }
    }
    
    func deleteItem(userId: String, key: ListItemType, item: String) async {
        
        let value = [
                    key.rawValue : FieldValue.arrayRemove([item])
                    ]
        do {
            try await database.collection("users").document(userId).updateData(value)
        } catch {
            debugPrint(String.boom, "deleteItem: \(error)")
        }
    }
    
    func deleteMoreItem(userId: String, listName: String, item: String, collectionName: String) async {
        
        let value = [
                    listName : FieldValue.arrayRemove([item])
                    ]
        do {
            try await database.collection(collectionName).document(userId).updateData(value)
        } catch {
            debugPrint(String.boom, "deleteItem moreLists: \(error)")
        }
    }
    
    func deleteFieldFromMoreItems(docID: String, listName: String, collectionName: String) async -> Bool {
        do {
          try await database.collection(collectionName).document(docID).updateData([
            listName: FieldValue.delete(),
          ])
            return true
        } catch {
            debugPrint(String.boom, "Error deleteFieldFromMoreItems: \(error)")
            return false
        }
    }
    
    func updateItemsForMoreItems(userId: String, listName: String, item: String, collectionName: String) async {
        
        let value = [
                    listName : FieldValue.arrayUnion([item])
                    ]
        do {
            try await database.collection(collectionName).document(userId).updateData(value)
        } catch {
            debugPrint(String.boom, "updateItemsForMoreItems: \(error)")
        }
    }
    
    func addItem(userId: String, key: ListItemType, item: String) async {
        
        let value = [
                    key.rawValue : FieldValue.arrayUnion([item])
                    ]
        do {
            try await database.collection("users").document(userId).updateData(value)
        } catch {
            debugPrint(String.boom, "addItem: \(error)")
        }
    }
    
    func updateItem(userId: String, items: [String], listName: String, collectionName: String) async {
        let value = [
                    listName : items,
                    ]
        do {
            try await database.collection(collectionName).document(userId).updateData(value)
        } catch {
            debugPrint(String.boom, "updateItem: \(error)")
        }
    }
    
    func updateShared(id: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let value = [
                        "sharedWith" : FieldValue.arrayUnion([id])
                    ]
        do {
            try await database.collection("users").document(currentUid).updateData(value)
        } catch {
            debugPrint(String.boom, "updateShared: \(error)")
        }
    }
    
    func deleteShared(id: String) async {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        
        let value = [
                        "sharedWith" : FieldValue.arrayRemove([id])
                    ]
        do {
            try await database.collection("users").document(currentUid).updateData(value)
        } catch {
            debugPrint(String.boom, "deleteShared: \(error)")
        }
    }
    
    func callFirebaseCallableFunction(fcm: String, title: String, body: String, silent: Bool) {
        lazy var functions = Functions.functions()
        
        let payload = [
                        "silent": silent,
                        "fcm": fcm,
                        "title": title,
                        "body": body
        ] as [String : Any]
        functions.httpsCallable("sendNotification").call(payload) { result, error in
            if let error = error as NSError? {
                debugPrint(String.boom, "Errror callFirebaseCallableFunction \(error.localizedDescription)")
            }
            if let data = result?.data {
                debugPrint("result: \(data)")
            }
            
        }
    }
*/

}
