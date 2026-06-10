//
//  DrumFactory.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 09/06/26.
//

import RealityKit
import SwiftUI
import ARKit

@MainActor
struct DrumFactory{
    static func createDrum(for type: DrumType) -> Entity{
        let entity = Entity()
        entity.name = type.rawValue
        
        let mesh : MeshResource = .generateCylinder(height: 0.01, radius: 0.2)
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: type.color)
        material.metallic  = 0.1
        material.roughness = 0.6
        
        let model = ModelEntity(mesh: mesh, materials: [material])
        entity.addChild(model)
        
        let shape = ShapeResource.generateBox(width: 0.4, height: 0.01, depth: 0.4)
        entity.components.set(CollisionComponent(shapes: [shape]))
        
        entity.components.set(InputTargetComponent())
        entity.components.set(InputTargetComponent())
        
        entity.position = SIMD3<Float>(0, 1.2, -1.0)
        
        entity.components.set(DrumComponent(type: type))
        entity.components.set(DrumAnimationComponent(isAnimating: false, originalScale: entity.transform.scale, animationStartTime: 0))
        
        return entity
    }
}
