//
//  AddingNewStockView.swift
//  MyTasks
//
//  Created by Larry Shannon on 2/25/24.
//

import SwiftUI

struct AddingNewStockView: View {
    @EnvironmentObject var dataModel: DataModel
    @EnvironmentObject var portfolioService: PortfolioService
    @Environment(\.dismiss) var dismiss
    var key: String
    @State var symbol: String = ""
    @State var basis: String = ""
    @State var quantity: String = ""
    @State var isDisabled = true
    @FocusState private var focusedField: FocusedField?
    
    enum FocusedField {
        case symbol, quantity, basis
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section {
                        TextField("Symbol", text: $symbol)
                            .focused($focusedField, equals: .symbol)
                            .onChange(of: symbol) { oldValue, newValue in
                                if newValue.count <= 4 {
                                    symbol = String(newValue).uppercased()
                                } else {
                                    symbol = oldValue
                                }
                            }
                    } header: {
                        Text("Stock Symbol")
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
                            .keyboardType(.numberPad)
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
                    .disabled(isDisabled)
                }
            }
            .onChange(of: symbol) { oldValue, newValue in
                isDisabled = newValue.isEmpty
            }
            .onAppear {
                focusedField = .symbol
            }
        }
    }
    
    func add() {
        let item = ItemData(symbol: symbol, basis: Decimal(string: basis) ?? 0, price: 0, gainLose: 0, quantity: Int(quantity) ?? 0)
        Task {
            await portfolioService.addStock(listName: key, item: item)
            dismiss()
        }
    }
}

#Preview {
    AddingNewStockView(key: "aaa")
}
