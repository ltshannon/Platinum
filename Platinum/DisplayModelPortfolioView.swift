//
//  DisplayModelPortfolioView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/8/24.
//

import SwiftUI

struct DisplayModelPortfolioView: View {
    @EnvironmentObject var platinumGrowthModel: PlatinumGrowthModel
    @State var showingSheet = false
    @State var firstTime = true
    @State var segment: PlatinumGrowType = .notSet
    
    var body: some View {
        VStack {
            Picker("", selection: $segment) {
                ForEach(PlatinumGrowType.allCases, id: \.self) {
                    if $0 != .notSet {
                        Text($0.rawValue)
                    }
                }
            }
            .pickerStyle(.segmented)

            ScrollView {
                VStack {
                    if let model = platinumGrowthModel.allocationAndModeData {
                        if segment == .modelPortfolio {
                            ForEach(model.modelPortfolio, id: \.id) { item in
                                Text(item.type.rawValue)
                                    .foregroundStyle(.red)
                                ForEach(item.modelPortfolioData, id: \.id) { value in
                                    HStack {
                                        Text(value.symbol)
                                        Text(value.stockAction.rawValue)
                                            .foregroundStyle(getActionColor(stockAction: value.stockAction))
                                    }
                                }
                            }
                        } else if segment == .allocationTool {
                            ForEach(model.allocationTool, id: \.id) { item in
                                Text(item.type.rawValue)
                                    .foregroundStyle(.red)
                                ForEach(item.investments, id: \.id) { value in
                                    Text(value.investorType.rawValue)
                                    ForEach(value.stockInfomation, id: \.id) { stockInfomation in
                                        Text(stockInfomation.symbol)
                                    }
                                }
                            }
                        }
                    }
                }
                .fullScreenCover(isPresented: $showingSheet, onDismiss: didDismiss) {
                    GetPlatinumGrowthData()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSheet = true
                } label: {
                    Text("Refresh")
                }
            }
        }
        .onAppear {
            if firstTime {
                showingSheet = true
                firstTime = false
                platinumGrowthModel.allocationAndModeData  = AllocationAndModeData(type: .notSet, allocationTool: [], modelPortfolio: [], sevenDayRotation: [])
            }
        }
        .onChange(of: platinumGrowthModel.allocationAndModeData?.type) {
            debugPrint("🤢", "\(platinumGrowthModel.allocationAndModeData?.type ?? .notSet)")
            if platinumGrowthModel.allocationAndModeData?.type != .notSet {
                segment = platinumGrowthModel.allocationAndModeData?.type ?? .notSet
            }
        }
    }
    
    func didDismiss() {
        showingSheet = false
    }
    
    func getActionColor(stockAction: StockAction) -> Color {
        switch stockAction {
        case .new: return .green
        case .sell: return .red
        case .topStock: return .yellow
        case .none: return .clear
        }
    }
}

#Preview {
    DisplayModelPortfolioView()
}
