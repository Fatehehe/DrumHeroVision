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
        DrumSystem.registerSystem()
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
     }
}
