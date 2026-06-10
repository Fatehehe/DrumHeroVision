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
    
}
