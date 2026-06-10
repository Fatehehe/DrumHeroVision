//
//  DrumCatalogView.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 05/06/26.
//

import SwiftUI
import Combine

struct DrumCatalogView: View {
    @Environment(DrumWorkspaceViewModel.self) private var viewModel
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    
    // MARK: - State Skor & Timer
    @State private var currentScore: Int = 0
    let timer = Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
    
    let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 30)
    ]
    
    var body: some View {
        VStack(spacing: 30) {
            
            // MARK: - Tampilan Skor
            HStack {
                Spacer()
                VStack {
                    Text("SKOR")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    Text("\(currentScore)")
                        .font(.system(size: 64, weight: .bold, design: .rounded))
                        .foregroundStyle(.yellow)
                        // Memberikan efek animasi membesar sedikit saat skor berubah
                        .contentTransition(.numericText())
                }
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .glassBackgroundEffect()
                Spacer()
            }
            // Sinkronisasi skor secara berkala
            .onReceive(timer) { _ in
                // Pastikan kamu sudah menambahkan `static var sharedScore: Int = 0`
                // di dalam class DrumWorkspaceViewModel
                withAnimation {
                    currentScore = DrumWorkspaceViewModel.sharedScore
                }
            }
            
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
