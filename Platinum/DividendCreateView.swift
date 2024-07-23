//
//  DividendCreateView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/20/24.
//

import SwiftUI

struct DividendCreateView: View {
    @EnvironmentObject var portfolioService: PortfolioService
    @Environment(\.dismiss) private var dismiss
    var key: PortfolioType
    var symbol: String
    @State var dividendDate = Date()
    @State var dividendAmount = ""
    
    var body: some View {
        Form {
            Section {
                Text(symbol)
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
        .padding(20)
        Button("Add", action: addDividend)
            .buttonStyle(.borderedProminent)
        Button {
            dismiss()
        } label: {
            Text("Cancel")
        }
            .buttonStyle(.borderedProminent)
    }
    
    func addDividend() {
        dismiss()
        debugPrint("dividendAmount: \(dividendAmount)")
        debugPrint("dividendDate: \(dividendDate)")
        Task {
            await portfolioService.addDividend(listName: key.rawValue, symbol: symbol, dividendDate: dividendDate, dividendAmount: dividendAmount)
            await portfolioService.getDividend(listName: key.rawValue, symbol: symbol)
        }
    }

}
