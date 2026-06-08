//
//  DrumHitEvent.swift
//  DrumHeroVision
//
//  Created by Muhammad Benny Fathurrahman on 05/06/26.
//

import Foundation
import RealityKit

struct DrumHitEvent {
    let timestamp: TimeInterval
    let drumSurface: DrumType
    let worldPosition: SIMD3<Float>
}
