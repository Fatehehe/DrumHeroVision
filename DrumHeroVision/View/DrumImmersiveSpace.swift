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
    // Dictionary untuk menyimpan referensi entitas drum yang ada di scene
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
        .onAppear {
            DrumStickSystem.hitEventPublisher
                // Memastikan UI/State update berjalan di Main Thread
                .receive(on: RunLoop.main)
                .sink { event in
                    print("🥁 Hit → \(event.drumSurface.rawValue)")
                    
                    // 1. Cari entitas drum yang bersangkutan dari dictionary
                    if let entity = drumEntities[event.drumSurface] {
                        
                        // 2. Ambil komponen ECS-nya
                        if var drumComp = entity.components[DrumComponent.self] {
                            
                            // 3. Ubah state menjadi true
                            drumComp.isHit = true
                            
                            // 4. Pasang kembali ke entitas.
                            // (DrumSystem otomatis akan menangkap perubahan ini di frame berikutnya!)
                            entity.components.set(drumComp)
                        }
                    }
                }
                .store(in: &cancellables)
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
        // MARK: - Rotate Gesture (Twist)
        .gesture(
            RotateGesture3D()
                .targetedToAnyEntity()
                .onChanged { value in
                    let entity = value.entity
                    entity.transform.rotation = simd_quatf(value.rotation)
                }
        )
        .overlay(alignment: .bottom) {
            VStack {
                Text("Stick Length: \(String(format: "%.0f", stickLength * 100))cm")
                    .foregroundStyle(.white)
                Slider(value: $stickLength, in: 0.2...0.7, step: 0.05)
                    .frame(width: 300)
            }
            .padding()
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Spawn System
    private func spawnDrum(type: DrumType, in content: RealityViewContent) {
        let mesh = MeshResource.generateCylinder(height: 0.2, radius: 0.3)
        
        let material = SimpleMaterial(color: type.color, isMetallic: true)
        
        let drumEntity = ModelEntity(mesh: mesh, materials: [material])
        
        // 1. Tambahkan ECS Component
        drumEntity.components.set(DrumComponent(type: type, isHit: false))
        
        // 2. Tambahkan Collision & Input Target
        let shape = ShapeResource.generateBox(width: 0.6, height: 0.2, depth: 0.6)
        drumEntity.components.set(CollisionComponent(shapes: [shape]))
        drumEntity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        
        // 3. Set posisi awal
        drumEntity.position = SIMD3<Float>(0, 1.2, -1.0)
        
        content.add(drumEntity)
        
        // 4. Simpan entitas ke Dictionary secara asinkron
        // (Menggunakan DispatchQueue untuk menghindari warning SwiftUI "Modifying state during view update")
        DispatchQueue.main.async {
            drumEntities[type] = drumEntity
        }
    }
    
    // MARK: Spawn Stick
    private func spawnStickEntity(chirality: HandAnchor.Chirality, in content: RealityViewContent) {
        let mesh = MeshResource.generateCylinder(height: 1.0, radius: 0.008)
        
        var material = PhysicallyBasedMaterial()
        //Transparent
        let color = chirality == .left
        ? UIColor.systemBlue.withAlphaComponent(0.5) : UIColor.systemRed.withAlphaComponent(0.5)
        
        material.baseColor = .init(tint: color)
        material.blending = .transparent(opacity: .init(floatLiteral: 0.5))
        
        let stickEntity = ModelEntity(mesh: mesh, materials: [material])
        stickEntity.components.set(StickTipComponent(chirality: chirality, stickLength: Float(stickLength)))
        stickEntity.components.set(InputTargetComponent(allowedInputTypes: .indirect))
        
        let tipMesh     = MeshResource.generateSphere(radius: 0.012)
        var tipMaterial = UnlitMaterial()
        tipMaterial.color = .init(tint: .yellow.withAlphaComponent(0.8))
        
        //kalau mau pake tip acnhor
//        let tipAnchor = ModelEntity(mesh: tipMesh, materials: [tipMaterial])
//        tipAnchor.name = "tipAnchor"
//        
//        tipAnchor.position = SIMD3<Float>(0, 0.5, 0)
//        stickEntity.addChild(tipAnchor)
        
        //generate collision
        let collisionShape = ShapeResource.generateBox(
            width: 0.016, height: 1.0, depth: 0.016
        )
        stickEntity.components.set(CollisionComponent(
            shapes: [collisionShape],
            mode: .default
        )) //no bounce. detectiopn only
        
        stickEntity.isEnabled = false
        stickEntity.position = SIMD3<Float>(0, -10, 0)
        
        content.add(stickEntity)
    }
} 
