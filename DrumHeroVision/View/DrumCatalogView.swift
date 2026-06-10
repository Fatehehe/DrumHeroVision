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
    
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 30)
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Pilih Drum")
                .font(.extraLargeTitle)
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 30) {
                    ForEach(viewModel.availableDrums) { drum in
                        Button(action: {
                            viewModel.requestSpawn(for: drum.type)
                        }) {
                            VStack(spacing: 12) {
                                Image(systemName: drum.iconName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 80)
                                
                                Text(drum.type.rawValue.capitalized)
                                    .font(.title2)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .glassBackgroundEffect()
                        .disabled(drum.isSpawned)
                        .opacity(drum.isSpawned ? 0.4 : 1.0)
                    }
                }
                .padding(.horizontal, 40)
            }
        }
        .padding(.vertical, 40)
        .onAppear {
            Task {
                await openImmersiveSpace(id: "DrumImmersiveSpace")
            }
        }
    }
}
