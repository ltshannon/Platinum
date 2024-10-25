//
//  DividendEditView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/20/24.
//

import SwiftUI

struct DividendEditView: View {
    @EnvironmentObject var portfolioService: PortfolioService
    @Environment(\.dismiss) private var dismiss
    var key: PortfolioType
    var item: ItemData
    var dividendDisplayData: DividendDisplayData
    @State var dividendAmount = ""
    @State var dividendDate = Date()
    
    init(parameters: DividendEditParameters) {
        self.key = parameters.key
        self.item = parameters.item
        self.dividendDisplayData = parameters.dividendDisplayData
    }
    
    var body: some View {
        Form {
            Section {
                Text(dividendDisplayData.symbol)
            } header: {
                Text("Symbol")
            }
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
        .navigationBarHidden(true)
        Button("Update", action: updateDividend)
            .buttonStyle(.borderedProminent)
        Button("Delete", action: deleteDividend)
            .buttonStyle(.borderedProminent)
        Button("Cancel", action: cancelDividend)
            .buttonStyle(.borderedProminent)
        .onAppear {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "MM/dd/yyyy"
            dividendDate = dateFormatter.date(from: dividendDisplayData.date) ?? Date()
            dividendAmount = dividendDisplayData.price.formatted(.currency(code: "USD"))
        }
    }
    
    func deleteDividend() {
        Task {
            await portfolioService.deleteDividend(listName: key.rawValue, symbol: dividendDisplayData.symbol, dividendDisplayData: dividendDisplayData)
            await portfolioService.getDividend(key: key, symbol: dividendDisplayData.symbol)
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    func updateDividend() {
        Task {
            await portfolioService.updateDividend(listName: key.rawValue, symbol: dividendDisplayData.symbol, dividendDisplayData: dividendDisplayData, dividendDate: dividendDate, dividendAmount: dividendAmount)
            await portfolioService.getDividend(key: key, symbol: dividendDisplayData.symbol)
            await MainActor.run {
                dismiss()
            }
        }
    }
    
    func cancelDividend() {
        dismiss()
    }
}
