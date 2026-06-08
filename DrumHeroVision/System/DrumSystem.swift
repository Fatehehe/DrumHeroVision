//
//  DrumSystem.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 08/06/26.
//

import RealityKit
import Foundation
import UIKit // Wajib untuk UIColor

struct DrumSystem: System {
    // Query untuk mencari semua entitas drum
    private static let drumQuery = EntityQuery(where: .has(DrumComponent.self))
    
    // Cache dictionary statis agar file audio tidak di-load berulang kali dari storage
    // setiap kali dipukul (menghindari lag dan boros memori).
    private static var audioCache: [String: AudioFileResource] = [:]
    
    init(scene: Scene) {
        // Setup awal jika diperlukan
    }
    
    // Fungsi ini dipanggil terus-menerus setiap frame oleh RealityKit
    func update(context: SceneUpdateContext) {
        let drumEntities = context.entities(matching: Self.drumQuery, updatingSystemWhen: .rendering)
        
        for entity in drumEntities {
            // Ambil komponennya
            guard var drumComp = entity.components[DrumComponent.self] else { continue }
            
            // Jika status isHit bernilai true
            if drumComp.isHit {
                
                // 1. Bunyikan Suara
                playAudioFeedback(for: drumComp.type, on: entity)
                
                // 2. Berikan Visual Feedback (Flash Putih)
                provideVisualFeedback(on: entity)
                
                // 3. KEMBALIKAN state isHit ke false agar tidak berulang terus-menerus
                drumComp.isHit = false
                
                // 4. Simpan kembali komponen yang sudah di-update ke entitas
                entity.components.set(drumComp)
            }
        }
    }
    
    // MARK: - Audio Feedback
    private func playAudioFeedback(for type: DrumType, on entity: Entity) {
        let fileName = type.soundFile
        
        // Cek apakah file audio sudah pernah di-load ke dalam cache
        if let cachedAudio = Self.audioCache[fileName] {
            // Mainkan audio langsung dari entitas (suara akan terasa spasial dari arah drum)
            entity.playAudio(cachedAudio)
        } else {
            // Jika belum ada di cache, load file audio dari bundle aplikasi
            do {
                let audioResource = try AudioFileResource.load(named: fileName, in: nil)
                Self.audioCache[fileName] = audioResource // Simpan ke cache
                entity.playAudio(audioResource)
            } catch {
                print("⚠️ Gagal memuat file audio: \(fileName). Pastikan file .wav sudah dimasukkan ke Target project.")
            }
        }
    }
    
    // MARK: - Visual Feedback (Color Flash)
    private func provideVisualFeedback(on entity: Entity) {
        // Untuk memanipulasi visual, kita wajib menarik ModelComponent
        guard var modelComp = entity.components[ModelComponent.self] else { return }
        
        // 1. Simpan referensi material asli (warna bawaan drum)
        let originalMaterials = modelComp.materials
        
        // 2. Buat material kilatan berwarna putih menyala
        let flashMaterial = SimpleMaterial(color: .white, isMetallic: true)
        
        // 3. Timpa material entitas dengan warna kilatan putih
        modelComp.materials = [flashMaterial]
        entity.components.set(modelComp)
        
        // 4. Kembalikan ke material asli setelah 0.1 detik
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Cek ulang apakah komponen masih ada sebelum mengembalikan warnanya
            if var currentModelComp = entity.components[ModelComponent.self] {
                currentModelComp.materials = originalMaterials
                entity.components.set(currentModelComp)
            }
        }
    }
}
