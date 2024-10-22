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
    @State var navigationBarTitle = ""
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
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Number of shares")
                    }
                    Section {
                        TextField("Basis", text: $basis)
                            .focused($focusedField, equals: .basis)
                            .keyboardType(.decimalPad)
                    } header: {
                        Text("Cost Basis")
                    }
                }
                Button {
                    add()
                } label: {
                    Text("Add")
                }
                .buttonStyle(.borderedProminent)
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
                .buttonStyle(.borderedProminent)
            }
            .navigationBarHidden(true)
            .onAppear {
                if firstTime == false {
                    firstTime = true
                    focusedField = .symbol
                    if firebaseService.user.subscription == true && stockList.isEmpty == false {
                        selectedStock = stockList.first!
                        navigationBarTitle = key.rawValue.camelCaseToWords()
                    } else {
                        selectedStock = ""
                    }
                }
            }
        }
    }
    
    func add() {
        let item = ItemData(firestoreId: "", symbol: selectedStock, basis: Decimal(string: basis) ?? 0, price: 0, gainLose: 0, percent: 0, quantity: Double(quantity) ?? 0)
        Task {
            dismiss()
            await portfolioService.addStock(listName: key.rawValue, item: item)
        }
    }
}

#Preview {
    AddingNewStockView(key: .acceleratedProfits, stockList: [])
}
