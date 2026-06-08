//
//  DrumHeroVisionApp.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 05/06/26.
//

import SwiftUI
import RealityKit

@main
struct DrumHeroVisionApp: App {

    @State private var appModel = AppModel()
    @State private var viewModel = DrumWorkspaceViewModel()
    
    init() {
            DrumComponent.registerComponent()
        StickTipComponent.registerComponent()
        DrumStickSystem.registerSystem()
        }

    var body: some SwiftUI.Scene {
        WindowGroup {
                    DrumCatalogView()
                        .environment(viewModel)
                }
                
                ImmersiveSpace(id: "DrumImmersiveSpace") {
                    DrumImmersiveSpace()
                        .environment(viewModel)
                }
//        WindowGroup {
//            ContentView()
//                .environment(appModel)
//        }
//
//        ImmersiveSpace(id: appModel.immersiveSpaceID) {
//            ImmersiveView()
//                .environment(appModel)
//                .onAppear {
//                    appModel.immersiveSpaceState = .open
//                }
//                .onDisappear {
//                    appModel.immersiveSpaceState = .closed
//                }
//        }
//        .immersionStyle(selection: .constant(.mixed), in: .mixed)
     }
}
