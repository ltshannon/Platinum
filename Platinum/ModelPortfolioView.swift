//
//  ModelPortfolioView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/12/24.
//

import SwiftUI

struct ModelPortfolioView: View {
    var modelPortfolio: [ModelPortfolio]
    let columns: [GridItem] = [GridItem(.adaptive(minimum: 100))]
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, alignment: .leading) {
                ForEach(modelPortfolio, id: \.id) { item in
                    Section {
                        Group {
                            Text("Symbol")
                            Text("Action")
                            Text("In Portfolio")
                        }
                        .underline()
                        ForEach(item.modelPortfolioData, id: \.id) { value in
                            Text(value.symbol)
                            Text(value.stockAction.rawValue)
                                .foregroundStyle(value.stockAction.getActionColor(stockAction: value.stockAction))
                            Text(value.inPorfilio ? "Yes" : "No")
                                .foregroundStyle(value.inPorfilio ? .black : .red)
                        }
                    } header: {
                        Text(item.type.rawValue)
                            .bold()
                            .foregroundStyle(.blue)
                    }
                }
            }
        }
    }
}

#Preview {
    ModelPortfolioView(modelPortfolio: [])
}
