//
//  ListSymbolsView.swift
//  Platinum
//
//  Created by Larry Shannon on 8/5/24.
//

import SwiftUI

struct ListSymbolsView: View {
    @EnvironmentObject var appNavigationState: AppNavigationState
    @EnvironmentObject var portfolioService: PortfolioService
    @State var items: [String] = []
    var listName: PortfolioType
    let columns: [GridItem] = [
                                GridItem(.fixed(55), spacing: 3),
                                GridItem(.fixed(55), spacing: 3),
    ]
    
    var body: some View {
            ScrollView {
                LazyVGrid(columns: columns, alignment: .center) {
                    ForEach(items, id: \.self) { item in
                        Text(item)
                        Button {
                            let parameters = SymbolEditParameters(listName: listName, symbol: item)
                            appNavigationState.symbolEditView(parameters: parameters)
                        } label: {
                            Image(systemName: "pencil")
                        }
                    }
                }
            }
            .onReceive(portfolioService.$stockList) { symbols in
                items = symbols
            }
            .onAppear {
                Task {
                    let _ = await portfolioService.getSymbolList(listName: listName)
                }
            }

    }
}
