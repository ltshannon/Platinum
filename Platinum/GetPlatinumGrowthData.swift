//
//  GetPlatinumGrowthData.swift
//  Platinum
//
//  Created by Larry Shannon on 7/8/24.
//

import SwiftUI

struct GetPlatinumGrowthData: View {
    @EnvironmentObject var platinumGrowthModel: PlatinumGrowthModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack {
                AllocationAndModelView(allocationAndModeData: $platinumGrowthModel.allocationAndModeData)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "chevron.backward")
                                .resizable()
                                .scaledToFit()
                                .font(Font.system(size: 20, weight: .medium))
                            Text("Back")
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    GetPlatinumGrowthData()
}
