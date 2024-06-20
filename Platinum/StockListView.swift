//
//  ContentView.swift
//  MyTasks
//
//  Created by Larry Shannon on 2/25/24.
//

import SwiftUI

struct StockListView: View {
    @EnvironmentObject var dataModel: DataModel
    var key: String
    @StateObject var networkService = NetworkService()
    @State var showingSheet: Bool = false
    @State var firstTime = true
    @State var showSecondView: Bool = false
    @State var item: ItemData = ItemData(symbol: "", basis: 0, price: 0, gainLose: 0, quantity: 0)
    @State var total: Decimal = 0
    let columns: [GridItem] = [
                                GridItem(.fixed(60), spacing: 3),
                                GridItem(.fixed(45), spacing: 3),
                                GridItem(.fixed(80), spacing: 3),
                                GridItem(.fixed(80), spacing: 3),
                                GridItem(.fixed(80), spacing: 3),
                                GridItem(.fixed(40), spacing: 3)
    ]
    let currencyFormatter: NumberFormatter = {
      let formatter = NumberFormatter()
      formatter.numberStyle = .currency
      return formatter
    }()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .leading) {
                    Group {
                        Text("Symbol")
                        Text("Qty")
                        Text("Basis")
                        Text("Price")
                        Text("Total")
                        Text("Edit")
                    }
                    .underline()
                    ForEach(dataModel.items, id: \.id) { item in
                        Text("\(item.symbol)")
                        Text("\(item.quantity)")
                        Text("\(item.basis as NSDecimalNumber, formatter: currencyFormatter)")
                        Text("\(item.price as NSDecimalNumber, formatter: currencyFormatter)")
                        Text("\(abs(item.gainLose) as NSDecimalNumber, formatter: currencyFormatter)")
                            .foregroundStyle(item.gainLose < 0 ?.red : .green)
                        Button {
                            self.item = item
                            showSecondView.toggle()
                        } label: {
                            Image(systemName: "pencil")
                        }

                    }
                    Group {
                        Text("Total")
                        Text("")
                        Text("")
                        Text("")
                        Text("\(total as NSDecimalNumber, formatter: currencyFormatter)")
                            .foregroundStyle(total < 0 ? .red : .green)
                    }
                }
            }
            .navigationDestination(isPresented: $showSecondView) {
                StockDetailView(key: key, item: item)
             }
            .padding([.leading], 10)
            Spacer()
            Button {
                showingSheet = true
            } label: {
                VStack(alignment: .center) {
                    Image(systemName: "plus.circle")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                    Text("Add Stock")
                }
            }
            Spacer()
            .navigationBarTitle(key)
            .onAppear {
                updateValuesForStocks()
            }
            .fullScreenCover(isPresented: $showingSheet, onDismiss: didDismiss) {
                AddingNewStockView(key: key)
            }
        }
    }
    
    func didDismiss() {
        updateValuesForStocks()
    }
    
    func updateValuesForStocks() {
        Task {
            var total: Decimal = 0
            var items = await dataModel.restore(key: key)
            let array = items.map { $0.symbol }
            let string: String = array.joined(separator: ",")
            let data = await networkService.fetch(tickers: string)
            for item in data {
                if let row = items.firstIndex(where: { $0.symbol == item.id }) {
                    items[row].price = Decimal(Double(item.price))
                    let gainLose = Decimal(items[row].quantity) * (Decimal(Double(item.price)) - items[row].basis)
                    items[row].gainLose = gainLose
                    total += gainLose
                }
            }
            await MainActor.run {
                dataModel.items = items
                self.total = total
            }
        }
    }
    
}

#Preview {
    StockListView(key: "acceleratedProfits")
}
