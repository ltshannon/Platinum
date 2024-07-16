//
//  PlatinumGrowthModel.swift
//  Platinum
//
//  Created by Larry Shannon on 7/8/24.
//

import Foundation
import SwiftUI

class PlatinumGrowthModel: ObservableObject {
    static let shared = PlatinumGrowthModel()
    @Published var allocationAndModeData: AllocationAndModeData?
    @Published var showingAlert: Bool?
    @Published var alertMessage: String?
    
    func resetShowingAlert() {
        showingAlert?.toggle()
    }
    
}
