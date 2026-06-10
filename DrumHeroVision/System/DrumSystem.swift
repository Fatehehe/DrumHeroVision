//
//  DrumSystem.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 08/06/26.
//

import RealityKit
import Foundation
import UIKit

struct DrumSystem: System {
    private static let drumQuery = EntityQuery(where: .has(DrumComponent.self))
    private static var audioCache: [String: AudioFileResource] = [:]
    
    init(scene: Scene) {
    }
    
    static func HandleHit(drum: Entity, type: DrumType){
        playAudioFeedback(for: type, on: drum)
        checkRhythmHit(drum: drum, type: type)
    }
    
    private static func playAudioFeedback(for type: DrumType, on entity: Entity) {
        let fileName = type.soundFile
        
        if let cachedAudio = Self.audioCache[fileName] {
            entity.playAudio(cachedAudio)
        } else {
            do {
                let audioResource = try AudioFileResource.load(named: fileName, in: nil)
                Self.audioCache[fileName] = audioResource
                entity.playAudio(audioResource)
            } catch {
                print("Gagal memuat file audio: \(fileName). Pastikan file .wav sudah dimasukkan ke Target project.")
            }
        }
    }
    
    private static func checkRhythmHit(drum: Entity, type: DrumType) {
        let hitZoneRange: ClosedRange<Float> = -0.2...0.2 // Toleransi jarak Z
        var hitSuccessful = false
        
        // Cek semua anak (children) dari drum ini
        for child in drum.children {
            if let noteComp = child.components[RhythmNoteComponent.self], noteComp.drumType == type {
                // Cek posisi Z dari not tersebut
                let noteZPosition = child.position.z
                
                if hitZoneRange.contains(noteZPosition) {
                    // PERFECT HIT!
                    hitSuccessful = true
                    
                    // Tambah skor (update singleton/state manager)
                    DrumWorkspaceViewModel.sharedScore += 10
                    print("PERFECT HIT! Skor: \(DrumWorkspaceViewModel.sharedScore)")
                    
                    // Beri efek visual hancur (opsional) lalu hapus notnya
                    child.removeFromParent()
                    
                    break // Hanya hancurkan 1 not per pukulan
                }
            }
        }
        
        if !hitSuccessful {
            print("MISS!")
        }
    }
    
}
