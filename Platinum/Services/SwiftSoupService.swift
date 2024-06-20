//
//  SwiftSoupService.swift
//  Platinum
//
//  Created by Larry Shannon on 6/12/24.
//

import Foundation
import SwiftSoup

class SwiftSoupService: ObservableObject {
    @Published var eliteDividendPayersArray: [String] = []
    @Published var growthInvestorArray: [String] = []
    @Published var breakthroughStocksArray: [String] = []
    @Published var acceleratedProfitsArray: [String] = []
    
    func fetch() {
        Task {
            do {
                if let baseURL = URL(string: "https://investorplace.com/platinumgrowthclub/allocation-tool/") {
                    let session = URLSession(configuration: .default)
                    let response = try await session.data(from: baseURL)
                    if let string = String(data: response.0, encoding: .utf8) {
                        debugPrint("data: \(string)")
                    }
                }
            } catch {
                debugPrint("NetworkService error: \(error)")
            }
        }
    }
    
    func fetchWithPassword() {
        
        // Replace these with the actual login URL, form parameters, and field names.
        let loginUrl = URL(string: "https://investorplace.com/platinumgrowthclub/ipa-login/")!
        let username = "candice@breakawaydesign.com"
        let password = "Bisbee11!"

        var request = URLRequest(url: loginUrl)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        // Prepare your POST data with the necessary form fields
//        let postString = "_ipnonce=a9025d6b55&_wp_http_referer=%2Fplatinumgrowthclub%2Fipa-login%2F%3Fipa_action%3Dlogout&ipa_from=&ipa_home=https%3A%2F%2Finvestorplace.com%2Fplatinumgrowthclub%2F&ipa_source=primary&username=\(username)&password=\(password)"
        let postString = "_ipnonce=a9025d6b55&username=\(username)&password=\(password)"
        request.httpBody = postString.data(using: .utf8)

        let session = URLSession.shared

        // Perform login request
        let task = session.dataTask(with: request) { data, response, error in
            guard error == nil else {
                print("Error during the login request: \(error?.localizedDescription ?? "No error description")")
                return
            }

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                // Now you are logged in, and you can send further requests using the session instance.
                // Cookies, if any, will be handled automatically by the URLSession.

                // Replace this with the URL of the protected page you want to scrape
                let protectedPageUrl = URL(string: "https://investorplace.com/platinumgrowthclub/allocation-tool/")!
                let protectedPageRequest = URLRequest(url: protectedPageUrl)

                // Fetch the protected page
                let protectedPageTask = session.dataTask(with: protectedPageRequest) { [self] protectedPageData, protectedPageResponse, protectedPageError in
                    guard let protectedPageData = protectedPageData, protectedPageError == nil else {
                        print("Error fetching the protected page: \(protectedPageError?.localizedDescription ?? "No error description")")
                        return
                    }

                    // Parse the HTML content with SwiftSoup
                    do {
                        let html = String(data: protectedPageData, encoding: .utf8) ?? ""
                        let doc: Document = try SwiftSoup.parse(html)
                        guard let text = try? doc.text() else {
                            debugPrint("SwiftSoup failed on .text()")
                            return
                        }

                        guard let text2 = findAndRemove(text: text, search: "Conservative Moderate Aggressive") else {
                            debugPrint("Problem with finding Conservative Moderate Aggressive")
                            return
                        }

//                        guard let subString = getSubstring(text: text2, string: "Symbol Company Name Recent Price Buy Below Value Shares") else {
//                            debugPrint("Problem with finding Symbol Company Name Recent Price Buy Below Value Shares")
//                            return
//                        }
                        
                        guard let text3 = findAndRemove(text: text2, search: "Symbol Company Name Recent Price Buy Below Value Shares") else {
                            debugPrint("Symbol Company Name Recent Price Buy Below Value Shares")
                            return
                        }

                        guard var subString2 = getSubstring(text: text3, string: "Total Investment Value:") else {
                            debugPrint("Total Investment Value:")
                            return
                        }
                        subString2 = subString2.trimmingCharacters(in: .whitespacesAndNewlines)
                        let eliteDividendPayers = subString2.components(separatedBy: "– – ")
                        
                        Task {
                            await MainActor.run {
                                eliteDividendPayersArray = removeSymbol(array: eliteDividendPayers)
                            }
                        }
                        
                        guard let text4 = findAndRemove(text: text3, search: "Symbol Company Name Recent Price Buy Below Value Shares") else {
                            debugPrint("Symbol Company Name Recent Price Buy Below Value Shares")
                            return
                        }
                        
                        guard let subString3 = getSubstring(text: text4, string: "Total Investment Value:") else {
                            debugPrint("Total Investment Value:")
                            return
                        }
                        
                        let growthInvestor = subString3.components(separatedBy: "- - ")
                        Task {
                            await MainActor.run {
                                growthInvestorArray = removeSymbol(array: growthInvestor)
                            }
                        }
                        
                        guard let text5 = findAndRemove(text: text4, search: "Symbol Company Name Recent Price Buy Below Value Shares") else {
                            debugPrint("Symbol Company Name Recent Price Buy Below Value Shares")
                            return
                        }
                        
                        guard let subString4 = getSubstring(text: text5, string: "Total Investment Value:") else {
                            debugPrint("Total Investment Value:")
                            return
                        }
                        
                        let breakthroughStocks = subString4.components(separatedBy: "- -")
                        Task {
                            await MainActor.run {
                                breakthroughStocksArray = removeSymbol(array: breakthroughStocks)
                            }
                        }
                        
                        guard let text6 = findAndRemove(text: text5, search: "Symbol Company Name Recent Price Buy Below Value Shares") else {
                            debugPrint("Symbol Company Name Recent Price Buy Below Value Shares")
                            return
                        }
                        
                        guard let subString5 = getSubstring(text: text6, string: "Total Investment Value:") else {
                            debugPrint("Total Investment Value:")
                            return
                        }
                        
                        let acceleratedProfits = subString5.components(separatedBy: "- -")
                        Task {
                            await MainActor.run {
                                acceleratedProfitsArray = removeSymbol(array: acceleratedProfits)
                            }
                        }
                        
                        
                    } catch Exception.Error(_, let message) {
                        print("Error parsing HTML: \(message)")
                    } catch {
                        print("error")
                    }
                }
                protectedPageTask.resume()
            } else {
                print("Login failed with response: \(response.debugDescription)")
            }
        }

        task.resume()
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
            let substring = text[..<index]   // ab
            return String(substring)
        }
        return nil
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
            let range = self[startIndex...]
                .range(of: string, options: options) {
                result.append(range)
                startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                    index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
