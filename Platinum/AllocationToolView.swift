//
//  AllocationToolView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/11/24.
//

import SwiftUI

struct AllocationToolView: View {
    var investments: [Investment]
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, alignment: .leading) {
                ForEach(investments, id: \.id) { item in
                    Section {
                        Group {
                            Text("Symbol")
                            Text("Recent Price")
                            Text("Buy Below")
                        }
                        .underline()
                        ForEach(item.stockInfomation, id: \.id) { stockInfomation in
                            Text(stockInfomation.symbol)
                            Text("$\(stockInfomation.recentPrice as NSDecimalNumber, formatter: currencyFormatter)")
                            Text("$\(stockInfomation.buyBelow as NSDecimalNumber, formatter: currencyFormatter)")
                        }
                    } header: {
                        Text(item.investorType.rawValue)
                            .bold()
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
}

#Preview {
    AllocationToolView(investments: [])
}
