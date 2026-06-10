//
//  RythmSystem.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 10/06/26.
//

// Tambahkan di file baru atau di bawah DrumSystem
import RealityKit

struct RhythmSystem: System {
    static let noteQuery = EntityQuery(where: .has(RhythmNoteComponent.self))
    
    init(scene: Scene) {}
    
    func update(context: SceneUpdateContext) {
        let deltaTime = Float(context.deltaTime)
        
        for entity in context.scene.performQuery(Self.noteQuery) {
            guard let noteComp = entity.components[RhythmNoteComponent.self] else { continue }
            
            // Gerakkan mendekati drum (Z positif karena dari -3.0 menuju 0.0)
            entity.position.z += noteComp.speed * deltaTime
            
            // Kalau not sudah lewat jauh dari drum (miss), hapus entitasnya
            if entity.position.z > 0.5 {
                entity.removeFromParent()
            }
        }
    }
}
