//
//  DrumAnimationComponent.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 09/06/26.
//

import RealityKit
import Foundation

struct DrumAnimationComponent: Component {
    var isAnimating: Bool = false
    var originalScale: SIMD3<Float>
    var animationStartTime: TimeInterval = 0
}
