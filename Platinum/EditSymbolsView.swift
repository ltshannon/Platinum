//
//  EditSymbolsView.swift
//  Platinum
//
//  Created by Larry Shannon on 8/5/24.
//

import SwiftUI

struct EditSymbolsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var portfolioService: PortfolioService
    var listName: PortfolioType
    var symbol: String
    @State var showDeleteAlert = false
    @State var showUpdateAlert = false
    @State var newSymbol = ""
    
    init(paramters: SymbolEditParameters) {
        self.listName = paramters.listName
        self.symbol = paramters.symbol
    }
    
    var body: some View {
        VStack {
            Form {
                Section {
                    TextField("Symbol", text: $newSymbol)
                } header: {
                    Text("Stock Symbol")
                }
            }
            Group {
                Button {
                    if newSymbol == symbol {
                        showUpdateAlert = true
                        return
                    }
                    update()
                } label: {
                    Text("Update")
                }
                Button {
                    showDeleteAlert = true
                } label: {
                    Text("Delete")
                }
                Button {
                    dismiss()
                } label: {
                    Text("Cancel")
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .onAppear {
            newSymbol = symbol
        }
        .alert("Are you sure you want to delete this?", isPresented: $showDeleteAlert) {
            Button("Yes", role: .cancel) {
                delete()
            }
        }
        .alert("Nothing changed", isPresented: $showUpdateAlert) {
            Button("OK", role: .cancel) { }
        }
    }
    
    func delete() {
        Task {
            await portfolioService.deleteSymbol(listName: listName.rawValue, symbol: symbol)
            dismiss()
        }
    }
    
    func update() {

        Task {
            await portfolioService.updateSymbol(listName: listName.rawValue, newSymbol: newSymbol, oldSymbol: symbol)
            dismiss()
        }
    }
}
