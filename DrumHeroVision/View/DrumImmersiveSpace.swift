//
//  DrumImmersiveSpace.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 05/06/26.
//

import SwiftUI
import RealityKit
import ARKit
import Combine

struct DrumImmersiveSpace: View {
    @Environment(DrumWorkspaceViewModel.self) private var viewModel
    
    @State private var initialScale: SIMD3<Float> = .one
    @State private var cancellables = Set<AnyCancellable>()
    @AppStorage("stickLength") private var stickLength: Double = 0.4
    @State private var gestureStartLength: Double = 0.4
    
    // MARK: - ECS Bridge
    @State private var drumEntities: [DrumType: Entity] = [:]
    
    var body: some View {
        RealityView { content in
            spawnStickEntity(chirality: .right, in: content)
            spawnStickEntity(chirality: .left, in: content)
            
        } update: { content in
            if let type = viewModel.pendingSpawnType {
                spawnDrum(type: type, in: content)
                viewModel.pendingSpawnType = nil
            }
            
            for entity in content.entities {
                if var comp = entity.components[StickTipComponent.self] {
                    comp.stickLength = Float(stickLength)
                    entity.components.set(comp)
                }
            }
        }
        
        // MARK: - Drag Gesture
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    let entity = value.entity
                    entity.position = value.convert(value.location3D, from: .local, to: entity.parent!)
                }
        )
        // MARK: - Scale Gesture (Pinch)
        .gesture(
            MagnifyGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    let entity = value.entity
                    if initialScale == .one {
                        initialScale = entity.scale
                    }
                    let newScale = Float(value.magnification)
                    entity.scale = initialScale * newScale
                }
                .onEnded { _ in
                    initialScale = .one
                }
        )
    }
    
    // MARK: - Spawn System
    private func spawnDrum(type: DrumType, in content: RealityViewContent) {
        let mesh = MeshResource.generateCylinder(height: 0.2, radius: 0.3)
        
        let material = SimpleMaterial(color: type.color, isMetallic: true)
        
        let drumEntity = ModelEntity(mesh: mesh, materials: [material])
        
        // 1. Tambahkan ECS Component
        drumEntity.components.set(DrumComponent(type: type))
        
        // 2. Tambahkan Collision & Input Target
        let shape = ShapeResource.generateBox(width: 0.6, height: 0.2, depth: 0.6)
        drumEntity.components.set(CollisionComponent(shapes: [shape]))
        drumEntity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        
        // 3. Set posisi awal
        drumEntity.position = SIMD3<Float>(0, 1.2, -1.0)
        
        content.add(drumEntity)
        
        // ==========================================
        // 🌟 PERUBAHAN DI SINI 🌟
        // Panggil fungsi untuk spawn jalur dan note!
        // ==========================================
        spawnTrackAndNotes(for: drumEntity, type: type)
        
        // 4. Simpan entitas ke Dictionary secara asinkron
        DispatchQueue.main.async {
            drumEntities[type] = drumEntity
        }
    }
    
    // MARK: Spawn Stick
    private func spawnStickEntity(chirality: HandAnchor.Chirality, in content: RealityViewContent) {
        // ... (Kode spawn stick tetap sama) ...
        let mesh = MeshResource.generateCylinder(height: 1.0, radius: 0.008)
        
        var material = PhysicallyBasedMaterial()
        let color = chirality == .left
        ? UIColor.systemBlue.withAlphaComponent(0.5) : UIColor.systemRed.withAlphaComponent(0.5)
        
        material.baseColor = .init(tint: color)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.5))
        
        let stickEntity = ModelEntity(mesh: mesh, materials: [material])
        stickEntity.components.set(StickTipComponent(chirality: chirality, stickLength: Float(stickLength)))
        stickEntity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        
        let collisionShape = ShapeResource.generateBox(
            width: 0.016, height: 1.0, depth: 0.016
        )
        stickEntity.components.set(CollisionComponent(
            shapes: [collisionShape],
            mode: .default
        ))
        
        stickEntity.isEnabled = false
        stickEntity.position = SIMD3<Float>(0, -10, 0)
        
        content.add(stickEntity)
    }
    
    // MARK: Track & Note Spawner
    private func spawnTrackAndNotes(for drumEntity: Entity, type: DrumType) {
        // 1. Buat Track (Jalur)
        let trackMesh = MeshResource.generateBox(width: 0.2, height: 0.01, depth: 3.0)
        var trackMaterial = UnlitMaterial()
        trackMaterial.color = .init(tint: UIColor.white.withAlphaComponent(0.2))
        trackMaterial.blending = .transparent(opacity: .init(floatLiteral: 0.5))
        
        let trackEntity = ModelEntity(mesh: trackMesh, materials: [trackMaterial])
        trackEntity.position = SIMD3<Float>(0, -0.1, -1.5)
        drumEntity.addChild(trackEntity)
        
        // 2. Random Rhythm Spawner menggunakan Task
        Task {
            while !Task.isCancelled {
                guard drumEntity.parent != nil else { break }
                
                let randomInterval = Double.random(in: 0.8...2.5)
                try? await Task.sleep(nanoseconds: UInt64(randomInterval * 1_000_000_000))
                
                await MainActor.run {
                    spawnNote(on: drumEntity, type: type)
                }
            }
        }
    }

    private func spawnNote(on parentDrum: Entity, type: DrumType) {
        let noteMesh = MeshResource.generateSphere(radius: 0.08)
        let noteMaterial = SimpleMaterial(color: type.color, isMetallic: false)
        let noteEntity = ModelEntity(mesh: noteMesh, materials: [noteMaterial])
        
        noteEntity.components.set(RhythmNoteComponent(drumType: type, speed: 1.0))
        noteEntity.position = SIMD3<Float>(0, 0.1, -3.0)
        
        parentDrum.addChild(noteEntity)
    }
}
