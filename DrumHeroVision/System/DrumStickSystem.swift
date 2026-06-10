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
    
//    static let hitEventPublisher = PassthroughSubject<DrumHitEvent, Never>()
    private var isINsideZone: [HandAnchor.Chirality: Set<DrumType>] = [:]
    
    private var collisionSubscription: (any Cancellable)?
    
    required init(scene: RealityKit.Scene) {
        Task { await startARKitSession()}
        
        collisionSubscription = scene.subscribe(to: CollisionEvents.Began.self) { event in
            let drumEntity = event.entityA.components[DrumComponent.self] != nil
            ? event.entityA : event.entityB
            
            guard var drumComp = drumEntity.components[DrumComponent.self] else { return }
            
            guard
                let comp = drumEntity.components[DrumComponent.self]
            else { return }

            DrumSystem.HandleHit(
                drum: drumEntity,
                type: comp.type
            )
        }
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
            
            let stickEntities = context.entities(matching: Self.stickQuery, updatingSystemWhen: .rendering)
            guard let stickEntity = stickEntities.first(where: {
                $0.components[StickTipComponent.self]?.chirality == handAnchor.chirality
            }) else { continue }

            guard let skel = skeleton,
                  isGrippingStick(skeleton: skel, anchorToWorld: anchorToWorld) else {
                stickEntity.isEnabled = false
                continue
            }
            
            let length = stickEntity.components[StickTipComponent.self]?.stickLength ?? 0.4
            let stickCenter = thumbTipWorld + direction * (length / 2)
            
            stickEntity.scale       = SIMD3<Float>(1, length, 1)
            stickEntity.position    = stickCenter
            stickEntity.orientation = simd_quatf(from: SIMD3<Float>(0, 1, 0), to: direction)
            stickEntity.isEnabled   = true
            
            let otherAnchor = handAnchor.chirality == .left ? anchors.rightHand : anchors.leftHand
            if let otherAnchor, otherAnchor.isTracked,
               let otherSkeleton = otherAnchor.handSkeleton {
                
                let otherThumbLocal  = otherSkeleton.joint(.thumbTip).anchorFromJointTransform.columns.3
                let otherThumbWorld4 = otherAnchor.originFromAnchorTransform * otherThumbLocal
                let otherThumbPos    = SIMD3<Float>(otherThumbWorld4.x, otherThumbWorld4.y, otherThumbWorld4.z)
                
                let stickTip  = thumbTipWorld + direction * length
                let distToTip = simd_distance(otherThumbPos, stickTip)
                
                if distToTip < 0.03 {
                    let newLength = simd_distance(thumbTipWorld, otherThumbPos)
                    let clamped   = newLength
                    
                    if var comp = stickEntity.components[StickTipComponent.self] {
                        comp.stickLength = clamped
                        stickEntity.components.set(comp)
                    }
                    
                    UserDefaults.standard.set(Double(clamped), forKey: "stickLength")
                    print("📏 \(String(format: "%.0f", clamped * 100))cm")
                }
            }
        }
    }

    
    private func isGrippingStick(skeleton: HandSkeleton, anchorToWorld: simd_float4x4) -> Bool {
        print("gripping called")
        let fingers: [(knuckle: HandSkeleton.JointName, tip: HandSkeleton.JointName)] = [
            (.indexFingerKnuckle,  .indexFingerTip),
            (.middleFingerKnuckle, .middleFingerTip),
            (.ringFingerKnuckle,   .ringFingerTip),
            (.littleFingerKnuckle, .littleFingerTip)
        ]
        
        func worldPos(_ name: HandSkeleton.JointName) -> SIMD3<Float> {
            let local  = skeleton.joint(name).anchorFromJointTransform.columns.3
            let world4 = anchorToWorld * local
            return SIMD3<Float>(world4.x, world4.y, world4.z)
        }
        
        let wristPos = worldPos(.wrist)
        var curledCount = 0
        
        for finger in fingers {
            let knucklePos = worldPos(finger.knuckle)
            let tipPos     = worldPos(finger.tip)
            
            let palmDir   = normalize(knucklePos - wristPos)
            let fingerDir = normalize(tipPos - knucklePos)
            
            let dotProduct = dot(palmDir, fingerDir)
            
            if dotProduct < 0.5 {
                curledCount += 1
            }
            
        }
        
        return curledCount >= 3
    }



    
}

private extension float4x4 {
    var translation: SIMD3<Float> {
        SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

