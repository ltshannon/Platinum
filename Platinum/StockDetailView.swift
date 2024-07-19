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
    var key: PortfolioType
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
    @State var dividendAmount = ""
    @State private var showingPopover = false
    @State var dividendDate = Date()
    @State var dividendDisplayData: [DividendDisplayData] = []
    let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()
    let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }()
    
    let formatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.currencyCode = "USD"
        formatter.numberStyle = .currency
        return formatter
    }()
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter
    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Symbol", text: $symbol)
                } header: {
                    Text("Stock Symbol")
                }
                Section {
                    TextField("Quantity", text: $quantity)
                        .keyboardType(.numberPad)
                } header: {
                    Text("Number of shares")
                }
                Section {
                    TextField("Basis", text: $basis)
                        .onChange(of: basis) { oldValue, newValue in
                            debugPrint(oldValue)
                            debugPrint(newValue)
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
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Stock Basis")
                }
                Section {
                    Text(price)
                } header: {
                    Text("Stock Price")
                }
                if dividendDisplayData.count > 0 {
                    Section {
                        ForEach(dividendDisplayData, id: \.id) { item in
                            HStack {
                                Text(item.date)
                                Text(item.price, format: .currency(code: "USD"))
                            }
                        }
                    } header: {
                        Text("Dividends")
                    }
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
            if key == .eliteDividendPayers {
                Button {
                    dividendDate = Date()
                    dividendAmount = ""
                    showingPopover = true
                } label: {
                    Text("Add Dividend")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .onAppear {
            symbol = item.symbol
            quantity = String(item.quantity)
            basis = formatter.string(for: item.basis) ?? "n/a"
            price = item.price.formatted(.currency(code: "USD"))
            originalBasis = basis
            originalSymbol = symbol
            originalQuantity = quantity
            Task {
                await updateDividendValues()
            }
        }
        .alert(showAlertMessage, isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        }
        .alert("Are you sure you want to delete this?", isPresented: $showDeleteAlert) {
            Button("Yes", role: .cancel) {
                delete()
            }
        }
        .popover(isPresented: $showingPopover) {
            Form {
                Section {
                    DatePicker("", selection: $dividendDate, in: ...Date(), displayedComponents: .date)
                        .datePickerStyle(GraphicalDatePickerStyle())
                        .frame(maxHeight: 400)
                } header: {
                    Text("Select a date")
                }
                Section {
                    TextField("Amount", text: $dividendAmount)
                        .keyboardType(.decimalPad)
                } header: {
                    Text("Enter an Amount")
                }
            }
            .padding(20)
            Button("Add", action: addDividend)
                .buttonStyle(.borderedProminent)
            Button {
                showingPopover = false
            } label: {
                Text("Cancel")
            }
                .buttonStyle(.borderedProminent)
        }
    }
    
    func addDividend() {
        showingPopover = false
        debugPrint("dividendAmount: \(dividendAmount)")
        debugPrint("dividendDate: \(dividendDate)")
        Task {
            await portfolioService.addDividend(listName: key.rawValue, symbol: symbol, dividendDate: dividendDate, dividendAmount: dividendAmount)
            await updateDividendValues()
        }
    }
    
    func updateDividendValues() async {
        let array = await portfolioService.getDividend(listName: key.rawValue, symbol: symbol)
        var data: [DividendDisplayData] = []
        let _ = array.map {
            let value = $0.split(separator: ",")
            if value.count == 2 {
                if let dec = Decimal(string: String(value[1])) {
                    let item = DividendDisplayData(date: String(value[0]), price: dec)
                    data.append(item)
                }
            }
        }
        debugPrint("dividend: \(data)")
        await MainActor.run {
            dividendDisplayData = data
        }
    }
    
    func updatePortfolio(key: PortfolioType) async {
        let result = await portfolioService.getPortfolio(listName: key)
        await MainActor.run {
            switch key {
            case .acceleratedProfits:
                portfolioService.acceleratedProfitsList = result.0
                portfolioService.acceleratedProfitsTotal = result.1
                portfolioService.acceleratedProfitsStockList = result.2
            case .breakthroughStocks:
                portfolioService.breakthroughList = result.0
                portfolioService.breakthroughTotal = result.1
                portfolioService.breakthroughStockList = result.2
            case .eliteDividendPayers:
                portfolioService.eliteDividendPayersList = result.0
                portfolioService.eliteDividendPayersTotal = result.1
                portfolioService.eliteDividendPayersStockList = result.2
            case .growthInvestor:
                portfolioService.growthInvestorList = result.0
                portfolioService.growthInvestorTotal = result.1
                portfolioService.growthInvestorStockList = result.2
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
            await portfolioService.updateStock(listName: key.rawValue, symbol: symbol, originalSymbol: originalSymbol, quantity: Int(quantity) ?? 0, basis: basis)
            await updatePortfolio(key: key)
            dismiss()
        }
    }
    
    func delete() {
        Task {
            await portfolioService.deleteStock(listName: key.rawValue, symbol: symbol)
            await updatePortfolio(key: key)
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


