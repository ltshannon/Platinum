//
//  AddSymbolView.swift
//  Platinum
//
//  Created by Larry Shannon on 8/5/24.
//

import SwiftUI

struct AddSymbolView: View {
    @EnvironmentObject var portfolioService: PortfolioService
    @Environment(\.dismiss) private var dismiss
    @State var symbol: String = ""
    var listType: PortfolioType
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Symbol", text: $symbol)
                } header: {
                    Text("Stock Symbol")
                }
            }
            Group {
                Button {
                    saveSymbol()
                } label: {
                    Text("Save")
                }
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    func saveSymbol() {
        Task {
            await portfolioService.addSymbol(listName: listType.rawValue, symbol: symbol.uppercased())
            let _ = await portfolioService.getSymbolList(listName: listType)
            dismiss()
        }
    }
}
