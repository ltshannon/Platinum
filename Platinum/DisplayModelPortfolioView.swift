//
//  DisplayModelPortfolioView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/8/24.
//

import SwiftUI

struct DisplayModelPortfolioView: View {
    @EnvironmentObject var platinumGrowthModel: PlatinumGrowthModel
    @EnvironmentObject var portfolioService: PortfolioService
    @EnvironmentObject var firebaseService: FirebaseService
    @EnvironmentObject var userAuth: Authentication
    @State var showingSheet = false
    @State var firstTime = true
    @State var segment: PlatinumGrowType = .notSet
    @State var showingAlert = false
    @State var alertMessage = ""
    let columns: [GridItem] = [
                                GridItem(.fixed(55), spacing: 3),
                                GridItem(.fixed(100), spacing: 3),
                                GridItem(.fixed(80), spacing: 3),
                                GridItem(.fixed(55), spacing: 3),
                                GridItem(.fixed(80), spacing: 3),
    ]
    
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
                            LazyVGrid(columns: columns, alignment: .leading) {
                                Group {
                                    Text("Sym")
                                    Text("Date")
                                    Text("Below")
                                    Text("Own")
                                    Text("Basis")
                                }
                                Group {
                                    Text("----")
                                    Text("-----")
                                    Text("-----")
                                    Text("-----")
                                    Text("-----")
                                }
                                ForEach(model.sevenDayRotation, id: \.id) { item in
                                    Text(item.symbol)
                                        .foregroundStyle(item.stockAction.getActionColor(stockAction: item.stockAction))
                                    Text(item.buyDate)
                                    Text(item.buyBelow)
                                    Text(item.inPorfilio ? "Yes" : "No")
                                        .foregroundStyle(item.inPorfilio ? .black : .red)
                                    Text("\(item.portfilioBasis as NSDecimalNumber, formatter: currencyFormatter)")
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
        .onChange(of: platinumGrowthModel.allocationAndModeData?.sevenDayRotation) {
            if let temp = platinumGrowthModel.allocationAndModeData {
                let data = temp.sevenDayRotation
                updateSevenDayRotation(data: data)
            }
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
    
    func updateSevenDayRotation(data: [SevenDayRotationData]) {
        var sevenDayData = data
        if sevenDayData.count > 0 {
            Task {
                for type in PortfolioType.allCases {
                    let stockList = await firebaseService.getStockList(listName: type.rawValue)
                    for (index, item) in sevenDayData.enumerated() {
                        if stockList.contains(item.symbol) {
                            sevenDayData[index].inPorfilio = true
                            if let dec = portfolioService.getBasisForStockInPortfilio(portfolioType: type, symbol: item.symbol) {
                                sevenDayData[index].portfilioBasis = dec
                            }
                        }
                    }
                }
                await MainActor.run {
                    platinumGrowthModel.allocationAndModeData?.sevenDayRotation = sevenDayData
                }
            }
        }
    }
}

#Preview {
    DisplayModelPortfolioView()
}
