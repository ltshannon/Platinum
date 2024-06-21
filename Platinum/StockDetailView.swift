//
//  StockDetailView.swift
//  MyTasks
//
//  Created by Larry Shannon on 2/25/24.
//

import SwiftUI

struct StockDetailView: View {
    @EnvironmentObject var portfolioService: PortfolioService
    @Environment(\.dismiss) private var dismiss
    var key: String
    var item: ItemData
    @State var symbol: String = ""
    @State var basis: String = ""
    @State var price: String = ""
    @State var quantity: String = ""
    @State var originalSymbol: String = ""
    @State var originalBasis: String = ""
    @State var originalQuantity: String = ""
    @State var showAlert = false
    @State var showAlertMessage = ""
    @State var showDeleteAlert = false
    let currencyFormatter: NumberFormatter = {
      let formatter = NumberFormatter()
      formatter.numberStyle = .currency
      return formatter
    }()
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Symbol", text: $symbol)
                        .onChange(of: symbol) { oldValue, newValue in
                            if newValue.count <= 4 {
                                symbol = String(newValue).uppercased()
                            } else if newValue.count > 4 {
                                showAlert = true
                                showAlertMessage = "Invalid symbol"
                                symbol = oldValue
                            }
                        }
                } header: {
                    Text("Stock Symbol")
                }
                Section {
                    TextField("Quantity", text: $quantity)
                        .onChange(of: quantity) { oldValue, newValue in
                            if newValue.isEmpty {
                                quantity = ""
                                return
                            }
                            if Int(newValue) == nil {
                                showAlert = true
                                quantity = oldValue
                                showAlertMessage = "Invalid quantity"
                            }
                        }
                        .keyboardType(.numberPad)
                } header: {
                    Text("Number of shares")
                }
                Section {
                    TextField("Basis", text: $basis)
                        .onChange(of: basis) { oldValue, newValue in
                            var item = newValue
                            if item.contains("$") {
                                item = String(newValue.dropFirst())
                            }
                            if item.count == 0 {
                                basis = ""
                                return
                            }
                            if decimalFormat(stringNumber: item) == nil {
                                showAlert = true
                                showAlertMessage = "Invalid basis value"
                                basis = oldValue
                            }
                        }
                } header: {
                    Text("Stock Basis")
                }
                Section {
                    Text(price)
                } header: {
                    Text("Stock Price")
                }
            }
            Button {
                update()
            } label: {
                Text("Update")
            }
            .buttonStyle(.borderedProminent)

            Button {
                showDeleteAlert = true
            } label: {
                Text("Delete")
            }
            .buttonStyle(.borderedProminent)

        }
        .onAppear {
            symbol = item.symbol
            quantity = String(item.quantity)
            basis = item.basis.formatted(.currency(code: "USD"))
            price = item.price.formatted(.currency(code: "USD"))
            originalBasis = basis
            originalSymbol = symbol
            originalQuantity = quantity
        }
        .alert(showAlertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Are you sure you want to delete this?", isPresented: $showDeleteAlert) {
            Button("Yes", role: .cancel) {
                delete()
            }
        }
    }
    
    func update() {
        if symbol == originalSymbol && basis == originalBasis && quantity == originalQuantity {
            showAlertMessage = "Nothing changed to update"
            showAlert = true
            return
        }
        
        Task {
            await portfolioService.updateStock(listName: key, symbol: symbol, quantity: Int(quantity) ?? 0, basis: basis)
            dismiss()
        }
    }
    
    func delete() {
        Task {
            await portfolioService.deleteStock(listName: key, symbol: symbol)
            dismiss()
        }
    }
    
    func decimalFormat(stringNumber: String) -> Decimal? {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        if let number = numberFormatter.number(from: stringNumber) {
            return number.decimalValue
        }
        numberFormatter.numberStyle = .currency
        if let number = numberFormatter.number(from: stringNumber) {
            return number.decimalValue
        }

        return nil
    }
}


