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
    
    // State untuk menyimpan skala sementara saat pinch gesture
    @State private var initialScale: SIMD3<Float> = .one
    
    @State private var cancellables = Set<AnyCancellable>()
    @State var stickLength: Float = 0.2
    
    
    var body: some View {
        RealityView { content in
            // Setup scene awal jika diperlukan
            spawnStickEntity(chirality: .right, in: content)
            spawnStickEntity(chirality: .left, in: content)
            
        } update: { content in
            // Mengecek apakah ada request spawn dari ViewModel
            if let type = viewModel.pendingSpawnType {
                spawnDrum(type: type, in: content)
                viewModel.pendingSpawnType = nil // Reset state
            }
        }
        .onAppear {
            DrumStickSystem.hitEventPublisher
                .sink { event in
                    print("🥁 Hit → \(event.drumSurface.rawValue)")
                }
                .store(in: &cancellables)
        }

        // MARK: - Drag Gesture
        .gesture(
            DragGesture()
                .targetedToAnyEntity()
                .onChanged { value in
                    // Memindahkan posisi entitas sesuai drag di ruang 3D
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
                    // Mengkalikan skala awal dengan nilai pembesaran
                    let newScale = Float(value.magnification)
                    entity.scale = initialScale * newScale
                }
                .onEnded { _ in
                    initialScale = .one // Reset saat pinch selesai
                }
        )
        // MARK: - Rotate Gesture (Twist)
        // MARK: - Rotate Gesture (Twist)
                .gesture(
                    RotateGesture3D()
                        .targetedToAnyEntity()
                        .onChanged { value in
                            let entity = value.entity
                            // Menerapkan rotasi 3D dengan mengonversi ke simd_quatf
                            entity.transform.rotation = simd_quatf(value.rotation)
                        }
                )
    }
    
    // MARK: - Spawn System
    // MARK: - Spawn System
        private func spawnDrum(type: DrumType, in content: RealityViewContent) {
            let mesh = MeshResource.generateCylinder(height: 0.2, radius: 0.3)
            let material = SimpleMaterial(color: type == .snare ? .red : .blue, isMetallic: true)
            
            let drumEntity = ModelEntity(mesh: mesh, materials: [material])
            
            // 1. Tambahkan ECS Component kita
            drumEntity.components.set(DrumComponent(type: type))
            
            // 2. Tambahkan Collision & Input Target (Wajib untuk Gesture!)
            // PERBAIKAN: Gunakan Box sebagai proksi collision untuk silinder
            let shape = ShapeResource.generateBox(width: 0.6, height: 0.2, depth: 0.6)
            
            /* Alternatif jika ingin collision yang benar-benar mengikuti bentuk mesh silinder 100%:
             if let convexShape = try? ShapeResource.generateConvex(from: mesh) {
                 drumEntity.components.set(CollisionComponent(shapes: [convexShape]))
             }
            */
            
            drumEntity.components.set(CollisionComponent(shapes: [shape]))
            drumEntity.components.set(InputTargetComponent(allowedInputTypes: .indirect)) // Mengizinkan tap/pinch jari
            
            // 3. Set posisi awal
            drumEntity.position = SIMD3<Float>(0, 1.2, -1.0)
            
            content.add(drumEntity)
        }
    
    //Spawn Stick
    private func spawnStickEntity(chirality: HandAnchor.Chirality, in content: RealityViewContent) {
        let mesh = MeshResource.generateCylinder(height: stickLength, radius: 0.008)
        
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: chirality == .left ? .systemBlue : .systemRed)
        material.roughness = .init(floatLiteral: 0.3)
        material.metallic  = .init(floatLiteral: 0.8)
        
        let stickEntity = ModelEntity(mesh: mesh, materials: [material])
        stickEntity.components.set(StickTipComponent(chirality: chirality, stickLength: stickLength))
        stickEntity.position = SIMD3<Float>(0, -10, 0) // offscreen until system positions it
        
        content.add(stickEntity)
    }

}
