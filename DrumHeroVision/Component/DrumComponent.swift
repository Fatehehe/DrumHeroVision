//
//  DrumComponent.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 05/06/26.
//

import Foundation
import RealityKit

struct DrumComponent: Component, Codable {
    var type: DrumType
    
    init(type: DrumType) {
        self.type = type
    }
}
