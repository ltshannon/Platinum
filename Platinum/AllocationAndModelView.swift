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
    var recentPrice: Decimal = 0.0
    var buyBelow: Decimal = 0.0
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
    var inPorfilio = false
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

struct ModelPortfolio: Identifiable, Equatable {
    static func == (lhs: ModelPortfolio, rhs: ModelPortfolio) -> Bool {
        return true
    }
    
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
    case none = "none"
    case unknown = "UNKNOWN"
}

extension StockAction {
    
    func getActionColor(stockAction: StockAction) -> Color {
        switch stockAction {
        case .new: return .green
        case .sell: return .red
        case .topStock: return .yellow
        case .none: return .clear
        case .unknown: return .orange
        }
    }
    
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
    @Binding var showingAlert: Bool?
    @Binding var alertMessage: String?
    var debug = true
    
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
        var doc: Document = Document("")
        
        init(_ parent: AllocationAndModelView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            
            webView.evaluateJavaScript("document.body.innerHTML", completionHandler: { (value: Any!, error: Error!) -> Void in
                if error != nil {
                    debugPrint("evaluateJavaScript: \(error.localizedDescription)")
                    self.showAlert()
                    return
                }
                
                if let result = value as? String {
//                    debugPrint("value: \(result)")
                    self.processHTML(html: result)
                }
            })
        }
        
        func processHTML(html: String) {

            do {
                doc = try SwiftSoup.parse(html)
                guard let text = try? doc.text() else {
                    debugPrint("SwiftSoup failed on .text()")
                    self.showAlert()
                    return
                }
//                debugPrint("text: \(text)")
                if let allocationToolData = findAndRemove(text: text, search: "Conservative Moderate Aggressive") {
                    if parent.debug {
                        debugPrint("Processing Conservative Moderate Aggressive")
                    }
                    allocationTool = []
                    processAllocationTool(data: allocationToolData)
                    DispatchQueue.main.async {
                        self.parent.allocationAndModeData?.type = .notSet
                        self.parent.allocationAndModeData?.type = .allocationTool
                        self.parent.allocationAndModeData?.allocationTool = self.allocationTool
                    }
                } else if let rotation = findAndRemove(text: text, search: "Symbol Company Name Buy Date Buy Price Return Recent Price Buy Below ") {
                    if parent.debug {
                        debugPrint("7-Day Rotation")
                    }
                    sevenDayRotation = []
                    process7DayRotation(data: rotation)
                    DispatchQueue.main.async {
                        self.parent.allocationAndModeData?.type = .notSet
                        self.parent.allocationAndModeData?.type = .modelPortfolio
                        self.parent.allocationAndModeData?.sevenDayRotation =  self.sevenDayRotation
                    }
                    
                } else if let modelPortfolioData = findAndRemove(text: text, search: "Symbol Company Name Total Grade Buy Date Buy Price Return Recent Price Buy Below Yield ") {
                    if parent.debug {
                        debugPrint("Processing Model Portfolio")
                    }
                    modelPortfolio = []
                    processModelPortfolio(data: modelPortfolioData)
                    DispatchQueue.main.async {
                        self.parent.allocationAndModeData?.type = .notSet
                        self.parent.allocationAndModeData?.type = .modelPortfolio
                        self.parent.allocationAndModeData?.modelPortfolio = []
                        self.parent.allocationAndModeData?.modelPortfolio =  self.modelPortfolio
                    }
                }
            } catch Exception.Error(_, let message) {
                debugPrint("Error parsing HTML: \(message)")
                self.showAlert()
            } catch {
                debugPrint("error")
                self.showAlert()
            }
        }

        func processModelPortfolio(data: String) {
            var processData: String
            
            processData = data
            for investor in InvestorType.allCases {
                
                guard let text = getSubstring(text: processData, string: "Average Return: ") else {
                    debugPrint("processModelPortfolio Average Return:")
                    self.showAlert()
                    return
                }
//                debugPrint("data \(text)")
                if let result = removeModelPortfolioValues(string: text) {
                    let localModelPortfolio: ModelPortfolio = ModelPortfolio(type: investor, modelPortfolioData: result)
                    modelPortfolio.append(localModelPortfolio)
                }

                guard let modelPortfolioData = findAndRemove(text: processData, search: "Symbol Company Name Total Grade Buy Date Buy Price Return Recent Price Buy Below Yield ") else {
                    debugPrint("ModelPortfolio didn't find header")
                    return
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
            processData = processData.trimmingCharacters(in: .whitespacesAndNewlines)
            while processData.contains("$") {
                if let temp = getSubstring(text: processData, string: "$") {
                    let trimmed = temp.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let sym = getSubstring(text: trimmed, string: " ") {
                        symbol = sym
                    }

                    guard let text1 = findAndRemove(text: trimmed, search: " ") else {
                        debugPrint("process7DayRotation text1 not found")
                        self.showAlert()
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
                    self.showAlert()
                    return
                }
                if let price = getSubstring(text: temp2, string: " ") {
                    buyPrice = price
                }
                guard let temp3 = findAndRemove(text: temp2, search: " ") else {
                    debugPrint("process7DayRotation could not remove space 1")
                    self.showAlert()
                    return
                }
                if let percent = getSubstring(text: temp3, string: " ") {
                    returnPercent = percent.replacingOccurrences(of: "%", with: "")
                }
                guard let temp4 = findAndRemove(text: temp3, search: " ") else {
                    debugPrint("process7DayRotation could not remove space 2")
                    self.showAlert()
                    return
                }
                if let recent = getSubstring(text: temp4, string: " ") {
                    recentPrice = recent.replacingOccurrences(of: "$", with: "")
                }
                guard let temp5 = findAndRemove(text: temp4, search: " ") else {
                    debugPrint("process7DayRotation could not remove space 3")
                    self.showAlert()
                    return
                }
                if let below = getSubstring(text: temp5, string: " ") {
                    buyBelow = below.replacingOccurrences(of: "$", with: "")
                }
                guard let temp6 = findAndRemove(text: temp5, search: " ") else {
                    debugPrint("process7DayRotation could not remove space 4")
                    self.showAlert()
                    return
                }

                company = company.trimmingCharacters(in: .whitespacesAndNewlines)
                if parent.debug {
                    debugPrint("symbol: \(symbol)")
                    debugPrint("stockAction: \(stockAction.rawValue)")
                    debugPrint("company: \(company)")
                    debugPrint("buyDate: \(buyDate)")
                    debugPrint("buyPrice: \(buyPrice)")
                    debugPrint("returnPercent: \(returnPercent)")
                    debugPrint("recentPrice: \(recentPrice)")
                    debugPrint("buyBlow: \(buyBelow)")
                }
                
                let sevenDayRotationData = SevenDayRotationData(symbol: symbol, stockAction: stockAction, companyName: company, buyDate: buyDate, buyPrice: buyPrice, returnPercent: returnPercent, recentPrice: recentPrice, buyBelow: buyBelow)
                sevenDayRotation.append(sevenDayRotationData)
                processData = temp6
                company = ""
                stockAction = .none
            }
        }
        
        func processAllocationTool(data: String) {
            var processData: String

            processData = data
            
            for category in InvestmentCategory.allCases {
                
                var newAllocationTool = AllocationTool(type: category, investments: [])
                guard var elite = getSubstring(text: processData, string: "Symbol Company Name Recent Price Buy Below Value Shares") else {
                    debugPrint("AllocationTool Total Investment Value:")
                    self.showAlert()
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
                    self.showAlert()
                    return
                }
                
                var portfolioArray = array[0]
                guard let text3 = findAndRemove(text: processData, search: "Symbol Company Name Recent Price Buy Below Value Shares") else {
                    debugPrint("AllocationTool text3 findAndRemove Symbol Company Name Recent Price Buy Below Value Shares")
                    self.showAlert()
                    return
                }
                
                guard var subString2 = getSubstring(text: text3, string: "Total Investment Value:") else {
                    debugPrint("AllocationTool Total Investment Value:")
                    self.showAlert()
                    return
                }
                
                subString2 = subString2.trimmingCharacters(in: .whitespacesAndNewlines)
                
                let eliteDividendPayersArray = removeAllocationToolValues(string: subString2, portfolio: portfolioArray)
                let investmentEliteDividendPayers = Investment(investorType: .eliteDividendPayers, stockInfomation: eliteDividendPayersArray)
                newAllocationTool.investments.append(investmentEliteDividendPayers)
                
                guard let text4 = findAndRemove(text: text3, search: "Symbol Company Name Recent Price Buy Below Value Shares") else {
                    debugPrint("AllocationTool text4 findAndRemove Symbol Company Name Recent Price Buy Below Value Shares")
                    self.showAlert()
                    return
                }
                
                guard let subString3 = getSubstring(text: text4, string: "Total Investment Value:") else {
                    debugPrint("AllocationTool Total Investment Value:")
                    self.showAlert()
                    return
                }
                
                let growthInvestor = subString3.trimmingCharacters(in: .whitespacesAndNewlines)
                portfolioArray = array[1]
                let growthInvestorArray = removeAllocationToolValues(string: growthInvestor, portfolio: portfolioArray)
                let investmentGrowthInvestor = Investment(investorType: .growthInvestor, stockInfomation: growthInvestorArray)
                newAllocationTool.investments.append(investmentGrowthInvestor)
                
                guard let text5 = findAndRemove(text: text4, search: "Symbol Company Name Recent Price Buy Below Value Shares") else {
                    debugPrint("AllocationTool text5 findAndRemove Symbol Company Name Recent Price Buy Below Value Shares")
                    self.showAlert()
                    return
                }
                
                guard let subString4 = getSubstring(text: text5, string: "Total Investment Value:") else {
                    debugPrint("AllocationTool Total Investment Value:")
                    self.showAlert()
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
                    self.showAlert()
                    return
                }
                
                guard let subString5 = getSubstring(text: text6, string: "Total Investment Value:") else {
                    debugPrint("AllocationTool Total Investment Value:")
                    self.showAlert()
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
                    self.showAlert()
                    return
                }
                
                allocationTool.append(newAllocationTool)
                processData = text8
            }
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
                    var array: [String] = []

                    do {
                        let classSelector = try doc.getElementsByClass("js-stock-" + symbol)
                        let html = try classSelector.html()
                        let html2 = "<html><body>\(html)</body></html>"
//                        debugPrint("html2: \(html2)")
                        let doc2: Document = try SwiftSoup.parse(html2)
                        if let elements = try? doc2.getAllElements(){
                            for element in elements {
                                for textNode in element.textNodes() {
                                    let temp = textNode.text().trimmingCharacters(in: .whitespacesAndNewlines)
                                    if temp.isNotEmpty {
                                        array.append(temp)
                                    }
                                }
                            }
                        }
                        debugPrint("array: \(array)")
                    } catch {
                        debugPrint("doc.getElementsByClass: failed")
                    }
                    
                    for (index, item) in array.enumerated() {
                        switch index {
                        case 0: symbol = item
                        case 1: company = item
                        case 2: totalGrade = item
                        case 3: buyDate = item
                        case 4: buyPrice = item
                        case 5: returnPercent = item
                        case 6: recentPrice = item
                        case 7: buyBelow = item
                        case 8: yield = item
                        case 9:
                            switch item.uppercased() {
                            case StockAction.new.rawValue:
                                stockAction = .new
                            case StockAction.sell.rawValue:
                                stockAction = .sell
                            case StockAction.topStock.rawValue:
                                stockAction = .topStock
                            default:
                                stockAction = .unknown
                            }
                        default:
                            debugPrint("")
                        }
                    }
                    let modelPortfolioData = ModelPortfolioData(symbol: symbol, stockAction: stockAction, companyName: company, totalGrade: totalGrade, buyDate: buyDate, buyPrice: buyPrice, returnPercent: returnPercent, recentPrice: recentPrice, buyBelow: buyBelow, yield: yield, inPorfilio: false)
                    
                    modelPortfolioArray.append(modelPortfolioData)
                    
                    if stockAction != .none && array.count > 0 {
                        array.removeLast()
                    }
                    guard let last = array.last else {
                        debugPrint("removeModelPortfolioValues get last failed")
                        return nil
                    }
                    debugPrint("last: \(last)")
                    guard let temp2 = findAndRemove(text: processData, search: last) else {
                        debugPrint("removeModelPortfolioValues could not find last")
                        self.showAlert()
                        return nil
                    }
                    processData = temp2.trimmingCharacters(in: .whitespacesAndNewlines)
                    symbol = ""
                    stockAction = .none
                    company = ""
                    totalGrade = ""
                    buyDate = ""
                    buyPrice = ""
                    returnPercent = ""
                    recentPrice = ""
                    buyBelow = ""
                    yield = ""

                }
            }
            return modelPortfolioArray
        }
        
        func showAlert() {
            DispatchQueue.main.async {
                self.parent.showingAlert = false
                self.parent.alertMessage = "Failed to process webpage, try again."
                self.parent.showingAlert = true
            }
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
            var recentPrice: Decimal = 0.0
            var buyBelow: Decimal = 0.0
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
                    recentPrice = Decimal(Double(removeCurrency(string: temp2)) ?? 0.0)
                    temp2 = findAndRemove(text: temp2, search: " ") ?? ""
                    buyBelow = Decimal(Double(removeCurrency(string: temp2)) ?? 0.0)
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
