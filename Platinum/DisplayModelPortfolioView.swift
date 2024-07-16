//
//  DisplayModelPortfolioView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/8/24.
//

import SwiftUI

struct DisplayModelPortfolioView: View {
    @EnvironmentObject var platinumGrowthModel: PlatinumGrowthModel
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var userAuth: Authentication
    @State var showingSheet = false
    @State var firstTime = true
    @State var segment: PlatinumGrowType = .notSet
    @State var showingAlert = false
    @State var alertMessage = ""
    
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
                VStack(alignment: .leading) {
                    if let model = platinumGrowthModel.allocationAndModeData {
                        if segment == .modelPortfolio {
                            ModelPortfolioView(modelPortfolio: model.modelPortfolio)
                        } else if segment == .allocationTool {
                            if model.allocationTool.count > 0 {
                                AllocationToolView(investments: model.allocationTool[0].investments)
                            }
                        } else if segment == .sevenDayRotation {
                            ForEach(model.sevenDayRotation, id: \.id) { item in
                                HStack {
                                    Text(item.symbol)
                                    Text(item.stockAction.rawValue)
                                        .foregroundStyle(item.stockAction.getActionColor(stockAction: item.stockAction))
                                    Spacer()
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding([.leading, .trailing], 20)
                .fullScreenCover(isPresented: $showingSheet, onDismiss: didDismiss) {
                    GetPlatinumGrowthData()
                }
            }
            .alert(alertMessage, isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
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
                platinumGrowthModel.showingAlert = false
                platinumGrowthModel.alertMessage = ""
            }
        }
        .onChange(of: platinumGrowthModel.allocationAndModeData?.type) {
            debugPrint("🤢", "\(platinumGrowthModel.allocationAndModeData?.type ?? .notSet)")
            if platinumGrowthModel.allocationAndModeData?.type != .notSet {
                segment = platinumGrowthModel.allocationAndModeData?.type ?? .notSet
            }
        }
        .onChange(of: platinumGrowthModel.showingAlert) {
            if let changed = platinumGrowthModel.showingAlert {
                if changed {
                    showingAlert = true
                    alertMessage = platinumGrowthModel.alertMessage ?? ""
                }
            }
        }
        .onChange(of: platinumGrowthModel.allocationAndModeData?.modelPortfolio) {
            updateModelPortfolio(data: platinumGrowthModel.allocationAndModeData?.modelPortfolio)
        }
    }
    
    func didDismiss() {
        showingSheet = false
    }
    
    func updateModelPortfolio(data: [ModelPortfolio]?) {
        if var modelPortfolios = data, modelPortfolios.count > 0 {
            Task {
                for (index, portfolio) in modelPortfolios.enumerated() {
                    var listName = ""
                    switch portfolio.type {
                    case .acceleratedProfits: listName = PortfolioType.acceleratedProfits.rawValue
                    case .breakthroughStocks: listName = PortfolioType.breakthroughStocks.rawValue
                    case .eliteDividendPayers: listName = PortfolioType.eliteDividendPayers.rawValue
                    case .growthInvestor: listName = PortfolioType.growthInvestor.rawValue
                    }
                    let stockList = await firebaseService.getStockList(listName: listName)
                    for (index2, item) in portfolio.modelPortfolioData.enumerated() {
                        if stockList.contains(item.symbol) {
                            modelPortfolios[index].modelPortfolioData[index2].inPorfilio = true
                        }
                    }
                    let email = userAuth.email.lowercased()
                    if email.contains("lawrence.t.shannon@gmail.com") {
                            
                    }
                }
                await MainActor.run {
                    platinumGrowthModel.allocationAndModeData?.modelPortfolio = modelPortfolios
                }
            }
        }
    }
}

#Preview {
    DisplayModelPortfolioView()
}
