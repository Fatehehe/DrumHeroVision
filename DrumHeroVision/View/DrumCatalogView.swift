//
//  DrumCatalogView.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 05/06/26.
//

import SwiftUI

struct DrumCatalogView: View {
    @Environment(DrumWorkspaceViewModel.self) private var viewModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Pilih Drum")
                .font(.extraLargeTitle)
            
            HStack(spacing: 30) {
                ForEach(viewModel.availableDrums) { drum in
                    Button(action: {
                        viewModel.requestSpawn(for: drum.type)
                    }) {
                        VStack {
                            Image(systemName: drum.iconName)
                                .resizable()
                                .frame(width: 80, height: 80)
                            Text(drum.type.rawValue)
                        }
                        .padding()
                    }
                    .buttonStyle(.plain)
                    .glassBackgroundEffect()
                }
            }
        }
        .padding(40)
        .onAppear {
            Task {
                await openImmersiveSpace(id: "DrumImmersiveSpace")
            }
        }
    }
}
