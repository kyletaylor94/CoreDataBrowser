//
//  SimulatorCellView.swift
//  CoreDataBrowser
//
//  Created by Turdesan Csaba on 2026. 03. 09..
//

import Foundation
import SwiftUI

struct SimulatorCellView: View {
    let device: SimulatorDevice
    let searchVM: SearchViewModel
    let simulatorViewModel: SimulatorViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                searchVM.highlightMatch(in: device.name)
                    .font(.headline)
                searchVM.highlightMatch(in: simulatorViewModel.runTimeTextReplacing(device: device))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(device.state)
                .foregroundStyle(.green)
        }
        .padding(.vertical, 4)
    }
}
