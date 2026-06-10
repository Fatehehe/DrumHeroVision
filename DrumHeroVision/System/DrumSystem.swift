//
//  DrumSystem.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 08/06/26.
//

import RealityKit
import Foundation

struct DrumSystem: System {
    // Cache dictionary audio
    private static var audioCache: [String: AudioFileResource] = [:]
    
    // Simpan subscription event agar tidak hilang dari memori (ARC)
    private var collisionSubscription: EventSubscription?
    
    init(scene: Scene) {
        // Mendengarkan secara spesifik momen ketika dua collider saling bersentuhan
        self.collisionSubscription = scene.subscribe(to: CollisionEvents.Began.self) { event in
            self.onCollision(event)
        }
    }
    
    // Fungsi update() sekarang bisa dibiarkan kosong, sangat hemat CPU!
    func update(context: SceneUpdateContext) {}
    
    // MARK: - Logic Benturan
    private func onCollision(_ event: CollisionEvents.Began) {
        let entityA = event.entityA
        let entityB = event.entityB
        
        var drumEntity: Entity?
        
        // Cek apakah benturan terjadi antara "Drum" dan "Stik"
        let isA_Drum = entityA.components.has(DrumComponent.self)
        let isA_Stick = entityA.components.has(StickTipComponent.self)
        let isB_Drum = entityB.components.has(DrumComponent.self)
        let isB_Stick = entityB.components.has(StickTipComponent.self)
        
        if isA_Drum && isB_Stick {
            drumEntity = entityA
        } else if isB_Drum && isA_Stick {
            drumEntity = entityB
        }
        
        // Jika benar drum dipukul stik, mainkan suara!
        if let drum = drumEntity, let drumComp = drum.components[DrumComponent.self] {
            playAudioFeedback(for: drumComp.type, on: drum)
        }
    }
    
    // MARK: - Audio Feedback
    private func playAudioFeedback(for type: DrumType, on entity: Entity) {
        let fileName = type.soundFile
        
        if let cachedAudio = Self.audioCache[fileName] {
            entity.playAudio(cachedAudio)
        } else {
            do {
                let audioResource = try AudioFileResource.load(named: fileName, in: nil)
                Self.audioCache[fileName] = audioResource
                entity.playAudio(audioResource)
            } catch {
                print("⚠️ Gagal memuat file audio: \(fileName)")
            }
        }
    }
}
