//
//  DrumComponent.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 05/06/26.
//

import Foundation
import RealityKit

struct DrumComponent: Component, Codable {
    var isHit: Bool = false
    var type: DrumType
    
    init(type: DrumType, isHit: Bool = false) {
        self.type = type
        self.isHit = isHit
    }
}
