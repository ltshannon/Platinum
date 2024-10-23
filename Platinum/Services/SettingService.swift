//
//  SettingService.swift
//  Platinum
//
//  Created by Larry Shannon on 10/23/24.
//

import Foundation

class SettingsService: ObservableObject {
    static let shared = SettingsService()
    @Published var isShowSoldStocks: Bool = false
    
    func toggleShowSoldStocks() {
        isShowSoldStocks.toggle()
    }
}
