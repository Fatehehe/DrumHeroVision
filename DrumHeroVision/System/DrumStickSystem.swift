//
//  DrumStickSystem.swift
//  DrumHeroVision
//
//  Created by Muhammad Benny Fathurrahman on 05/06/26.
//

import ARKit
import RealityKit
import Combine

@MainActor
class DrumStickSystem: System {
    
    //Sticks Entity
    private static let stickQuery = EntityQuery(where: .has(StickTipComponent.self))
    //Drum DSurface entity
    private static let drumQuery = EntityQuery(where: .has(DrumComponent.self))
    
    private let arSession = ARKitSession()
    private let handTracking = HandTrackingProvider()
    
    static let hitEventPublisher = PassthroughSubject<DrumHitEvent, Never>()
    private let hitCoolDown: TimeInterval = 0.1
    private var lastHitTime: [DrumType: TimeInterval] = [:]
    
    required init(scene: RealityKit.Scene) {
        Task { await startARKitSession()}
    }
    
    private func startARKitSession() async {
        guard HandTrackingProvider.isSupported else {
            print("Hd Supported")
            return
        }
        do {
            //only need the handtracking
            try await arSession.run([handTracking])
            print("Hd Started")
        } catch {
            print("Hd Failed to Start")
        }
    }
    
    func update(context: SceneUpdateContext) {
        let drumEntities = context.entities(matching: Self.drumQuery, updatingSystemWhen: .rendering)
        
        let anchors = handTracking.latestAnchors
        let handAnchors: [HandAnchor] = [anchors.leftHand, anchors.rightHand].compactMap { $0 }
        
        for handAnchor in handAnchors {
            guard handAnchor.isTracked else { continue }
            
            let skeleton = handAnchor.handSkeleton  // ← on the single handAnchor, not the array
            
            guard let wristJoint    = skeleton?.joint(HandSkeleton.JointName.wrist),
                  let thumbTipJoint = skeleton?.joint(HandSkeleton.JointName.thumbTip)
            else { continue }
            
            let anchorToWorld = handAnchor.originFromAnchorTransform
            let wristLocal    = wristJoint.anchorFromJointTransform.columns.3
            let thumbLocal    = thumbTipJoint.anchorFromJointTransform.columns.3
            
            let wristWorld4   = anchorToWorld * wristLocal
            let thumbWorld4   = anchorToWorld * thumbLocal
            
            let wristWorld    = SIMD3<Float>(wristWorld4.x, wristWorld4.y, wristWorld4.z)
            let thumbTipWorld = SIMD3<Float>(thumbWorld4.x, thumbWorld4.y, thumbWorld4.z)
            
            let rawDir      = thumbTipWorld - wristWorld
            let direction   = length(rawDir) > 0 ? normalize(rawDir) : SIMD3<Float>(0, -1, 0)
            let stickTipPos = thumbTipWorld + direction * 0.4
            
            checkHit(stickTipPos: stickTipPos, drumEntities: Array(drumEntities))
        }
    }

    
    private func checkHit(stickTipPos: SIMD3<Float>, drumEntities: [Entity]) {
        let now = Date().timeIntervalSinceReferenceDate

        for drum in drumEntities {
            guard var drumComp = drum.components[DrumComponent.self] else { continue }

            let distance = simd_distance(stickTipPos, drum.position(relativeTo: nil))

            guard distance < 0.15 else { continue }

            let last = lastHitTime[drumComp.type] ?? 0
            guard (now - last) > hitCoolDown else { continue }

            lastHitTime[drumComp.type] = now

            DrumStickSystem.hitEventPublisher.send(DrumHitEvent(
                timestamp: now,
                drumSurface: drumComp.type,
                worldPosition: stickTipPos
            ))
            
            drumComp.isHit = true

            print("🥁 Hit: \(drumComp.type.rawValue)")
        }
    }

    
}

private extension float4x4 {
    var translation: SIMD3<Float> {
        SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

