//
//  DrumModel.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 05/06/26.
//

import Foundation
import RealityKit

enum DrumType: String, CaseIterable, Codable{
    case snare = "Snare"
    case bass = "Bass"
    case hihat = "Hi-hat"
    
    var modelName: String{
        return "\(self.rawValue.lowercased())_model"
    }
}

struct DrumModel: Identifiable{
    let id = UUID()
    let type: DrumType
    let iconName: String
}
