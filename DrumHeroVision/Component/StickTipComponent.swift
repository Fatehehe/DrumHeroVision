//
//  StickTipComponent.swift
//  DrumHeroVision
//
//  Created by Muhammad Benny Fathurrahman on 05/06/26.
//

import RealityKit
import ARKit

public struct StickTipComponent: Component {
    var chirality: HandAnchor.Chirality
    var stickLength: Float = 0.2
    
    public init(chirality: HandAnchor.Chirality, stickLength: Float = 0.2) {
        self.chirality = chirality
        self.stickLength = stickLength
    }
}
