//
//  AllocationAndModelView.swift
//  Platinum
//
//  Created by Larry Shannon on 7/6/24.
//

import SwiftUI
import WebKit
import SwiftSoup

struct StockInformation: Identifiable {
    var id: String = UUID().uuidString
    var portfolio = ""
    var symbol = ""
    var company = ""
    var recentPrice = 0.0
    var buyBelow = 0.0
    var value = 0.0
    var numberOfShare = 0
}

struct AllocationTool: Identifiable {
    var id: String = UUID().uuidString
    var type: InvestmentCategory
    var investments: [Investment]
}

struct ModelPortfolioData: Identifiable {
    var id: String = UUID().uuidString
    var symbol: String = ""
    var stockAction: StockAction = .none
    var companyName: String = ""
    var totalGrade: String = ""
    var buyDate: String = ""
    var buyPrice: String = ""
    var returnPercent: String = ""
    var recentPrice: String = ""
    var buyBelow: String = ""
    var yield: String = ""
}

struct SevenDayRotationData: Identifiable {
    var id: String = UUID().uuidString
    var symbol: String = ""
    var stockAction: StockAction = .none
    var companyName: String = ""
    var buyDate: String = ""
    var buyPrice: String = ""
    var returnPercent: String = ""
    var recentPrice: String = ""
    var buyBelow: String = ""
}

struct ModelPortfolio: Identifiable {
    var id: String = UUID().uuidString
    var type: InvestorType
    var modelPortfolioData: [ModelPortfolioData]
}

enum  InvestmentCategory: String, CaseIterable {
    case conservative = "Conservative"
    case moderate = "Moderate"
    case aggressive = "Aggressive"
}

struct Investment: Identifiable {
    var id: String = UUID().uuidString
    var investorType: InvestorType
    var stockInfomation: [StockInformation]
}

enum InvestorType: String, CaseIterable {
    case eliteDividendPayers = "Elite Dividend Payers"
    case growthInvestor = "Growth Investor"
    case breakthroughStocks = "Breakthrough Stocks"
    case acceleratedProfits = "Accelerated Profits"
}

enum TotalGrade: String, CaseIterable {
    case a = "A"
    case b = "B"
    case c = "C"
}

enum StockAction: String, CaseIterable {
    case new = "NEW"
    case sell = "SELL"
    case topStock = "TOP STOCK"
    case none = ""
}

enum PlatinumGrowType: String, CaseIterable {
    case allocationTool = "Allocation Tool"
    case modelPortfolio = "Model Portfolio"
    case sevenDayRotation = "7-Day Rotation"
    case notSet = "Not set"
    
}

struct AllocationAndModeData {
    var type: PlatinumGrowType
    var allocationTool: [AllocationTool]
    var modelPortfolio: [ModelPortfolio]
    var sevenDayRotation: [SevenDayRotationData]
}

struct AllocationAndModelView: UIViewRepresentable {
    @Binding var allocationAndModeData: AllocationAndModeData?
    
    func updateUIView(_ uiView: WKWebView, context: Context) {

    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    var url: String = "https://investorplace.com/platinumgrowthclub/ipa-login/"

    func makeUIView(context: Context) -> WKWebView {
        let view = WKWebView()
        view.navigationDelegate = context.coordinator
        view.load(URLRequest(url:URL(string: url)!))
        return view
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: AllocationAndModelView
        var allocationTool: [AllocationTool] = []
        var modelPortfolio: [ModelPortfolio] = []
        var sevenDayRotation: [SevenDayRotationData] = []
        
        init(_ parent: AllocationAndModelView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            
            webView.evaluateJavaScript("document.body.innerHTML", completionHandler: { (value: Any!, error: Error!) -> Void in
                if error != nil {
                    debugPrint("evaluateJavaScript: \(error.localizedDescription)")
                    return
                }
                
                if let result = value as? String {
//                    debugPrint("value: \(result)")
                    self.processHTML(html: result)
                }
            })
        }
        
        func processHTML(html: String) {
            let text = "<iframe src=\"https://www.googletagmanager.com/ns.html?id=GTM-GTM-N7BC\" height=\"0\" width=\"0\" style=\"display:none;visibility:hidden\"> Skip to Content Investorplace Louis\' Services Growth Investor Accelerated Profits Power Portfolio Breakthrough Stocks AI Advantage Portfolio Grader Dividend Grader Market360 My Account My Services Portfolio Tracker Manage Account Support Logout Platinum Growth Club Primary Menu Search for: Home Issues & Alerts Special Reports Portfolios Model Portfolio 7-Day Rotation Allocation Tool Member Resources About Us Support Contact Us Disclosures & Disclaimers Privacy Policy Terms of Use Ad Choices Do Not Sell My Personal Information Cookie Preferences 7-Day Rotation Select Portfolio Model Portfolio Export CSV Print Louis Navellier’s stocks that will perform well in the next seven days. Learn more about this portfolio. Symbol Company Name Buy Date Buy Price Return Recent Price Buy Below ALAR Alarum Technologies Ltd. 06/03/24 $36.47 2.41% $37.35 $52.00 ANF Abercrombie & Fitch Co. 05/06/24 $129.38 34.56% $174.10 $199.00 AROC Archrock, Inc. 03/25/24 $19.40 5.93% $20.55 $21.00 CSWC Capital Southwest Corporation 03/11/24 $24.59 9.31% $26.88 $28.00 INSW International Seaways, Inc. 07/01/24 $59.20 -3.40% $57.19 $66.00 LLY New Eli Lilly & Co. 07/08/24 $918.00 2.37% $939.78 $979.00 MPLX New MPLX LP 07/08/24 $42.33 -1.18% $41.83 $46.00 PGR Progressive Corporation 04/15/24 $206.59 1.65% $209.99 $218.00 TRGP New Targa Resources Corp. 07/08/24 $132.55 0.26% $132.89 $137.00 VITL Vital Farms, Inc. 06/03/24 $43.11 5.08% $45.30 $56.00 Average Return: 5.70% Facebook Twitter Linkedin About Us Support Contact Us Disclosures & Disclaimers Privacy Policy Terms of Use Ad Choices Do Not Sell My Personal Information Cookie Preferences Financial Market Data powered by FinancialContent Services, Inc. All rights reserved. Nasdaq quotes delayed at least 15 minutes, all others at least 20 minutes. Copyright © 2024 InvestorPlace Media, LLC. All rights reserved. 1125 N Charles St, Baltimore, MD 21201."
            
            if let rotation = findAndRemove(text: text, search: "7-Day Rotation") {
                debugPrint("7-Day Rotation")
                process7DayRotation(data: rotation)
            }
            
        }
/*
            do {
                let doc: Document = try SwiftSoup.parse(html)
                guard let text = try? doc.text() else {
                    debugPrint("SwiftSoup failed on .text()")
                    return
                }
                debugPrint("text: \(text)")
                if let allocationToolData = findAndRemove(text: text, search: "Conservative Moderate Aggressive") {
                    debugPrint("Processing Conservative Moderate Aggressive")
                    processAllocationTool(data: allocationToolData)
                    DispatchQueue.main.async {
                        self.parent.allocationAndModeData!.type = .notSet
                        self.parent.allocationAndModeData!.type = .allocationTool
                        self.parent.allocationAndModeData!.allocationTool = self.allocationTool
                    }
                } else if let modelPortfolioData = findAndRemove(text: text, search: "Model Portfolio") {
                    debugPrint("Processing Model Portfolio")
                    processModelPortfolio(data: modelPortfolioData)
                    DispatchQueue.main.async {
                        self.parent.allocationAndModeData!.type = .notSet
                        self.parent.allocationAndModeData!.type = .modelPortfolio
                        self.parent.allocationAndModeData!.modelPortfolio =  self.modelPortfolio
                    }
                } else if let rotation = findAndRemove(text: text, search: "7-Day Rotation") {
                    debugPrint("7-Day Rotation")
                    process7DayRotation(data: rotation)
                }
            } catch Exception.Error(_, let message) {
                print("Error parsing HTML: \(message)")
            } catch {
                print("error")
            }
        }
*/
        func processModelPortfolio(data: String) {
            var processData: String
            
            processData = data
            for investor in InvestorType.allCases {
                
                guard let modelPortfolioData = findAndRemove(text: processData, search: "Symbol Company Name Total Grade Buy Date Buy Price Return Recent Price Buy Below Yield ") else {
                    debugPrint("ModelPortfolio didn't find header")
                    return
                }
                guard let text = getSubstring(text: modelPortfolioData, string: "Average Return: ") else {
                    debugPrint("processModelPortfolio Average Return:")
                    return
                }
//                debugPrint("data \(text)")
                if let result = removeModelPortfolioValues(string: text) {
                    let localModelPortfolio: ModelPortfolio = ModelPortfolio(type: investor, modelPortfolioData: result)
                    modelPortfolio.append(localModelPortfolio)
                }

                processData = modelPortfolioData
            }
        }
        
        func process7DayRotation(data: String) {
            var processData: String
            var symbol = ""
            var stockAction: StockAction = .none
            var company = ""
            var buyDate = ""
            var buyPrice = ""
            var returnPercent = ""
            var recentPrice = ""
            var buyBelow = ""

            processData = data
            guard var elite = getSubstring(text: processData, string: "Symbol Company Name Buy Date Buy Price Return Recent Price Buy Below") else {
                debugPrint("process7DayRotation")
                return
            }
            guard let text1 = findAndRemove(text: processData, search: "Symbol Company Name Buy Date Buy Price Return Recent Price Buy Below") else {
                debugPrint("process7DayRotationfindAndRemove Symbol Company Name Buy Date Buy Price Return Recent Price Buy Below")
                return
            }
            processData = text1.trimmingCharacters(in: .whitespacesAndNewlines)
            while processData.contains("$") {
                if let temp = getSubstring(text: processData, string: "$") {
                    let trimmed = temp.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let sym = getSubstring(text: trimmed, string: " ") {
                        symbol = sym
                    }
                    guard let text1 = findAndRemove(text: trimmed, search: " ") else {
                        debugPrint("process7DayRotation text1 not found")
                        return
                    }
                    var array = text1.components(separatedBy: " ")
                    while array.isEmpty == false {
                        let item = array.removeFirst()
                        let temp = item.uppercased()
                        if temp.contains(StockAction.new.rawValue) {
                            stockAction = StockAction.new
                            continue
                        }
                        if temp.contains(StockAction.sell.rawValue) {
                            stockAction = StockAction.sell
                            continue
                        }
                        if temp.contains("TOP") {
                            stockAction = StockAction.topStock
                            continue
                        }
                        //            debugPrint("array 6: \(array)")
                        if let _ = isValidDate(dateString: item) {
                            buyDate = item
                            continue
                        }
                        company += item + " "
                    }
                }
                guard let temp2 = findAndRemove(text: processData, search: "$") else {
                    debugPrint("process7DayRotation could not remove $")
                    return
                }
                if let price = getSubstring(text: temp2, string: " ") {
                    buyPrice = price
                }
                guard let temp3 = findAndRemove(text: temp2, search: " ") else {
                    debugPrint("process7DayRotation could not remove space 1")
                    return
                }
                if let percent = getSubstring(text: temp3, string: " ") {
                    returnPercent = percent.replacingOccurrences(of: "%", with: "")
                }
                guard let temp4 = findAndRemove(text: temp3, search: " ") else {
                    debugPrint("process7DayRotation could not remove space 2")
                    return
                }
                if let recent = getSubstring(text: temp4, string: " ") {
                    recentPrice = recent.replacingOccurrences(of: "$", with: "")
                }
                guard let temp5 = findAndRemove(text: temp4, search: " ") else {
                    debugPrint("process7DayRotation could not remove space 3")
                    return
                }
                if let below = getSubstring(text: temp5, string: " ") {
                    buyBelow = below.replacingOccurrences(of: "$", with: "")
                }
                guard let temp6 = findAndRemove(text: temp5, search: " ") else {
                    debugPrint("process7DayRotation could not remove space 4")
                    return
                }

                company = company.trimmingCharacters(in: .whitespacesAndNewlines)
                debugPrint("symbol: \(symbol)")
                debugPrint("stockAction: \(stockAction.rawValue)")
                debugPrint("company: \(company)")
                debugPrint("buyDate: \(buyDate)")
                debugPrint("buyPrice: \(buyPrice)")
                debugPrint("returnPercent: \(returnPercent)")
                debugPrint("recentPrice: \(recentPrice)")
                debugPrint("buyBlow: \(buyBelow)")
                
                let sevenDayRotationData = SevenDayRotationData(symbol: symbol, stockAction: stockAction, companyName: company, buyDate: buyDate, buyPrice: buyPrice, returnPercent: returnPercent, recentPrice: recentPrice, buyBelow: buyBelow)
                sevenDayRotation.append(sevenDayRotationData)
                processData = temp6
                company = ""

            }
        }
        
        func processAllocationTool(data: String) {
            var processData: String

            processData = data
            for category in InvestmentCategory.allCases {
                var newAllocationTool = AllocationTool(type: category, investments: [])
                guard var elite = getSubstring(text: processData, string: "Symbol Company Name Recent Price Buy Below Value Shares") else {
                    debugPrint("AllocationTool Total Investment Value:")
                    return
                }
                
                elite = elite.trimmingCharacters(in: .whitespacesAndNewlines)
                var array = elite.components(separatedBy: "%")
                if let index = array.firstIndex(of: "") {
                    array.remove(at: index)
                }
                array = array.map { item in
                    return item.trimmingCharacters(in: .whitespacesAndNewlines) + "%"
                }
                if let temp = array.first {
                    if let index = array.lastIndex(of: temp) {
                        array.remove(at: index)
                    }
                }
                
                guard array.count == 4 else {
                    debugPrint("AllocationTool Number of portfolios is wrong")
                    return
                }
                
                var portfolioArray = array[0]
                guard let text3 = findAndRemove(text: processData, search: "Symbol Company Name Recent Price Buy Below Value Shares") else {
                    debugPrint("AllocationTool text3 findAndRemove Symbol Company Name Recent Price Buy Below Value Shares")
                    return
                }
                
                guard var subString2 = getSubstring(text: text3, string: "Total Investment Value:") else {
                    debugPrint("AllocationTool Total Investment Value:")
                    return
                }
                
                subString2 = subString2.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let eliteDividendPayersArray = removeAllocationToolValues(string: subString2, portfolio: portfolioArray)
                let investmentEliteDividendPayers = Investment(investorType: .eliteDividendPayers, stockInfomation: eliteDividendPayersArray)
                newAllocationTool.investments.append(investmentEliteDividendPayers)
                //        debugPrint("eliteDividendPayersArray: \(investmentEliteDividendPayers)")
                
                guard let text4 = findAndRemove(text: text3, search: "Symbol Company Name Recent Price Buy Below Value Shares") else {
                    debugPrint("AllocationTool text4 findAndRemove Symbol Company Name Recent Price Buy Below Value Shares")
                    return
                }
                
                guard let subString3 = getSubstring(text: text4, string: "Total Investment Value:") else {
                    debugPrint("AllocationTool Total Investment Value:")
                    return
                }
                
                let growthInvestor = subString3.trimmingCharacters(in: .whitespacesAndNewlines)
                portfolioArray = array[1]
                let growthInvestorArray = removeAllocationToolValues(string: growthInvestor, portfolio: portfolioArray)
                let investmentGrowthInvestor = Investment(investorType: .growthInvestor, stockInfomation: growthInvestorArray)
                newAllocationTool.investments.append(investmentGrowthInvestor)
                //        debugPrint("growthInvestorArray: \(growthInvestorArray)")
                
                guard let text5 = findAndRemove(text: text4, search: "Symbol Company Name Recent Price Buy Below Value Shares") else {
                    debugPrint("AllocationTool text5 findAndRemove Symbol Company Name Recent Price Buy Below Value Shares")
                    return
                }
                
                guard let subString4 = getSubstring(text: text5, string: "Total Investment Value:") else {
                    debugPrint("AllocationTool Total Investment Value:")
                    return
                }
                
                let breakthroughStocks = subString4.trimmingCharacters(in: .whitespacesAndNewlines)
                portfolioArray = array[2]
                let breakthroughStocksArray = removeAllocationToolValues(string: breakthroughStocks, portfolio: portfolioArray)
                let investmentbreakthroughStocks = Investment(investorType: .breakthroughStocks, stockInfomation: breakthroughStocksArray)
                newAllocationTool.investments.append(investmentbreakthroughStocks)
                //        debugPrint("breakthroughStocksArray: \(breakthroughStocksArray)")
                
                guard let text6 = findAndRemove(text: text5, search: "Symbol Company Name Recent Price Buy Below Value Shares") else {
                    debugPrint("AllocationTool text6 findAndRemove Symbol Company Name Recent Price Buy Below Value Shares")
                    return
                }
                
                guard let subString5 = getSubstring(text: text6, string: "Total Investment Value:") else {
                    debugPrint("AllocationTool Total Investment Value:")
                    return
                }
                
                let acceleratedProfits = subString5.trimmingCharacters(in: .whitespacesAndNewlines)
                portfolioArray = array[3]
                let acceleratedProfitsArray = removeAllocationToolValues(string: acceleratedProfits, portfolio: portfolioArray)
                let investmentAcceleratedProfits = Investment(investorType: .acceleratedProfits, stockInfomation: acceleratedProfitsArray)
                newAllocationTool.investments.append(investmentAcceleratedProfits)
                //        debugPrint("acceleratedProfitsArray: \(acceleratedProfitsArray)")
                
                guard let text8 = findAndRemove(text: text6, search: "Total Investment Value:") else {
                    debugPrint("AllocationTool Total Investment Value:")
                    return
                }
                
                allocationTool.append(newAllocationTool)
                processData = text8
            }
//            for item in self.allocationTool {
//                debugPrint("AllocationTool portfolio: \(item.type.rawValue)")
//                for item2 in item.investments {
//                    debugPrint("investments: \(item2.investorType.rawValue)")
//                    if item2.investorType == .eliteDividendPayers {
//                        for item3 in item2.stockInfomation {
//                            debugPrint("symbol: \(item3.symbol) recentPrice: \(item3.recentPrice) # shares: \(item3.numberOfShare)")
//                        }
//                    }
//                }
//            }
        }
        
        func removeModelPortfolioValues(string: String) -> [ModelPortfolioData]? {
            var processData: String
            var symbol = ""
            var stockAction: StockAction = .none
            var company = ""
            var totalGrade = ""
            var buyDate = ""
            var buyPrice = ""
            var returnPercent = ""
            var recentPrice = ""
            var buyBelow = ""
            var yield = ""
            var modelPortfolioArray: [ModelPortfolioData] = []
            
        //    debugPrint("string: \(string)")
            processData = string
            while processData.contains("$") {
                if let temp = getSubstring(text: processData, string: "$") {
                    let trimmed = temp.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let sym = getSubstring(text: trimmed, string: " ") {
                        symbol = sym
                    }
                    guard let text1 = findAndRemove(text: trimmed, search: " ") else {
                        debugPrint("removeModelPortfolioValues text1 not found")
                        return nil
                    }
                    var array = text1.components(separatedBy: " ")
                    //        debugPrint("array 1: \(array)")
                    stockAction = .none
                    while array.isEmpty == false {
                        let item = array.removeFirst()
                        //            debugPrint("array 2: \(array)")
                        //            debugPrint("item: \(item)")
                        let temp = item.uppercased()
                        if temp.contains(StockAction.new.rawValue) {
                            stockAction = StockAction.new
                            continue
                        }
                        if temp.contains(StockAction.sell.rawValue) {
                            stockAction = StockAction.sell
                            continue
                        }
                        if temp.contains("TOP") {
                            stockAction = StockAction.topStock
                            continue
                        }
                        if item.count == 1 {
                            for grade in TotalGrade.allCases {
                                switch grade {
                                case .a:
                                    if TotalGrade.a.rawValue == item {
                                        totalGrade = item
                                    }
                                case .b:
                                    if TotalGrade.b.rawValue == item {
                                        totalGrade = item
                                    }
                                case .c:
                                    if TotalGrade.c.rawValue == item {
                                        totalGrade = item
                                    }
                                }
                            }
                            continue
                        }
                        //            debugPrint("array 6: \(array)")
                        if let _ = isValidDate(dateString: item) {
                            buyDate = item
                            continue
                        }
                        company += item + " "
                        
                    }
                }
                guard let temp2 = findAndRemove(text: processData, search: "$") else {
                    debugPrint("removeModelPortfolioValues could not remove $")
                    return nil
                }
                if let price = getSubstring(text: temp2, string: " ") {
                    buyPrice = price
                }
                guard let temp3 = findAndRemove(text: temp2, search: " ") else {
                    debugPrint("removeModelPortfolioValues could not remove space 1")
                    return nil
                }
                if let percent = getSubstring(text: temp3, string: " ") {
                    returnPercent = percent.replacingOccurrences(of: "%", with: "")
                }
                guard let temp4 = findAndRemove(text: temp3, search: " ") else {
                    debugPrint("removeModelPortfolioValues could not remove space 2")
                    return nil
                }
                if let recent = getSubstring(text: temp4, string: " ") {
                    recentPrice = recent.replacingOccurrences(of: "$", with: "")
                }
                guard let temp5 = findAndRemove(text: temp4, search: " ") else {
                    debugPrint("removeModelPortfolioValues could not remove space 3")
                    return nil
                }
                if let below = getSubstring(text: temp5, string: " ") {
                    buyBelow = below.replacingOccurrences(of: "$", with: "")
                }
                guard let temp6 = findAndRemove(text: temp5, search: " ") else {
                    debugPrint("removeModelPortfolioValues could not remove space 4")
                    return nil
                }
                if let value = getSubstring(text: temp6, string: " ") {
                    yield = value.replacingOccurrences(of: "%", with: "")
                } else {
                    yield = temp6.replacingOccurrences(of: "%", with: "")
                    return nil
                }
                
                guard let temp7 = findAndRemove(text: temp6, search: " ") else {
                    debugPrint("removeModelPortfolioValues could not remove space 5")
                    return nil
                }
                company = company.trimmingCharacters(in: .whitespacesAndNewlines)
                debugPrint("symbol: \(symbol)")
                debugPrint("stockAction: \(stockAction.rawValue)")
                debugPrint("company: \(company)")
                debugPrint("totalGrade: \(totalGrade)")
                debugPrint("buyDate: \(buyDate)")
                debugPrint("buyPrice: \(buyPrice)")
                debugPrint("returnPercent: \(returnPercent)")
                debugPrint("recentPrice: \(recentPrice)")
                debugPrint("buyBlow: \(buyBelow)")
                debugPrint("yield: \(yield)")
                
                let modelPortfolioData = ModelPortfolioData(symbol: symbol, stockAction: stockAction, companyName: company, totalGrade: totalGrade, buyDate: buyDate, buyPrice: buyPrice, returnPercent: returnPercent, recentPrice: recentPrice, buyBelow: buyBelow, yield: yield)
                modelPortfolioArray.append(modelPortfolioData)
                processData = temp7
                company = ""

            }
            return modelPortfolioArray
        }

        func isValidDate(dateString: String) -> Date? {
            let dateFormatterGet = DateFormatter()
            dateFormatterGet.dateFormat = "MM/dd/yy"
            if let item = dateFormatterGet.date(from: dateString) {
                return item
            } else {
                return nil
            }
        }
        
        func removeAllocationToolValues(string: String, portfolio: String) -> [StockInformation] {
            var stockInformation: [StockInformation] = []
            var localString = ""
            
            localString = string
            while localString.contains("$") == true {
                let values = getStockInfo(portfolio: portfolio, string: localString)
                stockInformation.append(values.0)
                localString = values.1
            }
            
            return stockInformation
            
        }
        
        func getStockInfo(portfolio: String, string: String) -> (StockInformation, String)  {
            var symbol = ""
            var company = ""
            var recentPrice = 0.0
            var buyBelow = 0.0
            var value = 0.0
            var numberOfShare = 0
            var returnValue = ""
            
            if let temp = getSubstring(text: string, string: "$") {
                let trimmed = temp.trimmingCharacters(in: .whitespacesAndNewlines)
                if let sym = getSubstring(text: trimmed, string: " ") {
                    symbol = sym
                }
                if let value = findAndRemove(text: temp, search: " ") {
                    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
                    company = trimmed
                }
                
                if var temp2 = findAndRemove(text: string, search: "$") {
                    recentPrice = Double(removeCurrency(string: temp2)) ?? 0.0
                    temp2 = findAndRemove(text: temp2, search: " ") ?? ""
                    buyBelow = Double(removeCurrency(string: temp2)) ?? 0.0
                    temp2 = findAndRemove(text: temp2, search: " ") ?? ""
                    value = Double(removeCurrency(string: temp2)) ?? 0.0
                    temp2 = findAndRemove(text: temp2, search: " ") ?? ""
                    numberOfShare = Int(removeCurrency(string: temp2)) ?? 0
                    temp2 = findAndRemove(text: temp2, search: " ") ?? ""
                    returnValue = temp2
                }
            }
            
            let stockInfo = StockInformation(portfolio: portfolio, symbol: symbol, company: company, recentPrice: recentPrice, buyBelow: buyBelow, value: value, numberOfShare: numberOfShare)
            
            return (stockInfo, returnValue)
        }
        
        func removeCurrency(string: String) -> String {
            
            if let temp = getSubstring(text: string, string: " ") {
                let trimmed = temp.trimmingCharacters(in: .whitespacesAndNewlines)
                let value = trimmed.replacingOccurrences(of: "$", with: "")
                let value2 = value.replacingOccurrences(of: ",", with: "")
                return value2
            }
            
            return ""
        }
        
        func removeSymbol(array: [String]) -> [String] {
            let temp = array.map {
                let trimmed = $0.trimmingCharacters(in: .whitespacesAndNewlines)
                if let sym = getSubstring(text: trimmed, string: " ") {
                    return sym
                }
                return ""
            }
            return temp
        }
        
        func findAndRemove(text: String, search: String) -> String? {
            if let index = text.index(of: search) {
                var mySubstring = text[index...]
                let index2 = mySubstring.index(mySubstring.startIndex, offsetBy: search.count)
                mySubstring = text[index2...]
                return String(mySubstring)
            }
            return nil
        }
        
        func getSubstring(text: String, string: String) -> String? {
            if let index = text.index(of: string) {
                let substring = text[..<index]
                return String(substring)
            }
            return nil
        }
    }
}

extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
            let range = self[startIndex...].range(of: string, options: options) {
            result.append(range)
            startIndex = range.lowerBound < range.upperBound ? range.upperBound :
            index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}

