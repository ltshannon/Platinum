//
//  AddingNewStockView.swift
//  MyTasks
//
//  Created by Larry Shannon on 2/25/24.
//

import SwiftUI

struct AddingNewStockView: View {
    @EnvironmentObject var portfolioService: PortfolioService
    @EnvironmentObject var firebaseService: FirebaseService
    @Environment(\.dismiss) var dismiss
    var key: PortfolioType
    var stockList: [String]
    @State var basis: String = ""
    @State var quantity: String = ""
    @State var selectedStock = ""
    @State var firstTime = false
    @FocusState private var focusedField: FocusedField?
    
    enum FocusedField {
        case symbol, quantity, basis
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    if firebaseService.user.subscription == true {
                        Section {
                            List {
                                Picker("Stock Symbol", selection: $selectedStock) {
                                    ForEach(stockList, id: \.self) { stock in
                                        Text(stock)
                                    }
                                }
                            }
                            .pickerStyle(.navigationLink)
                        }
                    } else {
                        Section {
                            TextField("Stock Symbol", text: $selectedStock)
                                .textCase(.uppercase)
                                .disableAutocorrection(true)
                        } header: {
                            Text("Stock Symbol")
                        }
                    }
                    Section {
                        TextField("Quantity", text: $quantity)
                            .focused($focusedField, equals: .quantity)
                            .keyboardType(.numberPad)
                    } header: {
                        Text("Number of shares")
                    }
                    Section {
                        TextField("Basis", text: $basis)
                            .focused($focusedField, equals: .basis)
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Stock Basis")
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Text("Add Stock").font(.headline)
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                       add()
                    } label: {
                        Text("Add")
                    }
                }
            }
            .onAppear {
                if firstTime == false {
                    firstTime = true
                    focusedField = .symbol
                    if firebaseService.user.subscription == true && stockList.isEmpty == false {
                        selectedStock = stockList.first!
                    } else {
                        selectedStock = ""
                    }
                }
            }
        }
    }
    
    func add() {
        let item = ItemData(symbol: selectedStock, basis: Decimal(string: basis) ?? 0, price: 0, gainLose: 0, quantity: Int(quantity) ?? 0)
        Task {
            await portfolioService.addStock(listName: key.rawValue, item: item)
            dismiss()
        }
    }
}

#Preview {
    AddingNewStockView(key: .acceleratedProfits, stockList: [])
}
