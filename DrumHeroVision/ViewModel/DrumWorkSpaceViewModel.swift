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
    var availableDrums: [DrumModel] = [
        DrumModel(type: .snare, iconName: "circle.circle"),
        DrumModel(type: .hihat, iconName: "record.circle"),
        DrumModel(type: .ride, iconName: "circle.dotted"),
        DrumModel(type: .crash, iconName: "circle.slash"),
        DrumModel(type: .tom1, iconName: "circle.dashed"),
        DrumModel(type: .tom2, iconName: "circle.hexagonpath"),
        DrumModel(type: .tom2, iconName: "circle.hexagongrid")
    ]
    
    var pendingSpawnType: DrumType?
    
    func requestSpawn(for type: DrumType) {
        for index in availableDrums.indices {
            if availableDrums[index].type == type {
                availableDrums[index].isSpawned = true
            }
        }
        pendingSpawnType = type
    }
}
