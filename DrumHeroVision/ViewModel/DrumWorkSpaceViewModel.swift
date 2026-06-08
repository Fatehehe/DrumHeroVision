//
//  DrumWorkSpaceViewModel.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 05/06/26.
//

import SwiftUI
import RealityKit

@Observable
class DrumWorkspaceViewModel {
    let availableDrums: [DrumModel] = [
        DrumModel(type: .snare, iconName: "circle.circle"),
        DrumModel(type: .ride, iconName: "circle.circle.fill"),
        DrumModel(type: .hihat, iconName: "record.circle")
    ]
    
    var pendingSpawnType: DrumType?
    
    func requestSpawn(for type: DrumType) {
        pendingSpawnType = type
    }
}
