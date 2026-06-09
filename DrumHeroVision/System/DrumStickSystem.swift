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
    private var isINsideZone: [HandAnchor.Chirality: Set<DrumType>] = [:]
//    private let hitCoolDown: TimeInterval = 0.1
//    private var lastHitTime: [DrumType: TimeInterval] = [:]
    
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
            
            guard let skel = skeleton, isGrippingStick(skeleton: skel, anchorToWorld: anchorToWorld) else {continue}
                
            checkHit(stickTipPos: stickTipPos, chirality: handAnchor.chirality, drumEntities: Array(drumEntities))
            

        }
    }

    
    private func checkHit(stickTipPos: SIMD3<Float>,chirality: HandAnchor.Chirality, drumEntities: [Entity]) {
        var currentInZone = isINsideZone[chirality] ?? Set<DrumType>()

        for drum in drumEntities {
            guard var drumComp = drum.components[DrumComponent.self] else { continue }

            let distance = simd_distance(stickTipPos, drum.position(relativeTo: nil))
            
            let wasInsideBefore = currentInZone.contains(drumComp.type)
            
            let enterThreshold: Float = 0.15
            let exitThreshold: Float = 0.22
            
            let isNowInside: Bool
            
            if wasInsideBefore {
                isNowInside = distance < exitThreshold
            } else {
                isNowInside = distance < enterThreshold
            }
            
            if isNowInside {
                currentInZone.insert(drumComp.type)
            } else {
                currentInZone.remove(drumComp.type)
            }
            
            guard isNowInside && !wasInsideBefore else {continue}
            
            drumComp.isHit = true
            drum.components.set(drumComp)
            print("🥁 Hit: \(drumComp.type.rawValue)")
        }
        
        isINsideZone[chirality] = currentInZone
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
            
            
            //print("[\(finger.knuckle)] dot: \(dotProduct)")
        }
        
        return curledCount >= 3
    }



    
}

private extension float4x4 {
    var translation: SIMD3<Float> {
        SIMD3<Float>(columns.3.x, columns.3.y, columns.3.z)
    }
}

