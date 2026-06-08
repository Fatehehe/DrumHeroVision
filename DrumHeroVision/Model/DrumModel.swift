//
//  DrumModel.swift
//  DrumHeroVision
//
//  Created by Fatakhillah Khaqo on 05/06/26.
//

import Foundation
import RealityKit

import Foundation
import RealityKit
import SwiftUI
import UIKit // Dibutuhkan untuk UIColor

enum DrumType: String, CaseIterable, Identifiable, Codable {
    case snare, hihat, ride, crash
    case tom1, tom2, tom3
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .snare: return "Snare"
        case .hihat: return "Hi-Hat"
        case .ride:  return "Ride"
        case .crash: return "Crash"
        case .tom1:  return "Hi Tom"
        case .tom2:  return "Mid Tom"
        case .tom3:  return "Lo Tom"
        }
    }
    
    var soundFile: String {
        switch self {
        case .snare: return "snare.wav"
        case .hihat: return "hihat.wav"
        case .ride:  return "ride.wav"
        case .crash: return "crash.wav"
        case .tom1:  return "tom_high.wav"
        case .tom2:  return "tom_mid.wav"
        case .tom3:  return "tom_low.wav"
        }
    }
    
    var color: UIColor {
        switch self {
        case .snare: return UIColor(white: 0.85, alpha: 1)
        case .tom1:  return UIColor(red: 0.10, green: 0.30, blue: 0.55, alpha: 1)
        case .tom2:  return UIColor(red: 0.10, green: 0.45, blue: 0.25, alpha: 1)
        case .tom3:  return UIColor(red: 0.45, green: 0.10, blue: 0.45, alpha: 1)
        case .hihat: return UIColor(red: 0.85, green: 0.70, blue: 0.10, alpha: 1)
        case .ride:  return UIColor(red: 0.80, green: 0.60, blue: 0.10, alpha: 1)
        case .crash: return UIColor(red: 0.75, green: 0.65, blue: 0.05, alpha: 1)
        }
    }
    
    /// Nama model USDZ untuk load aset 3D
    var modelName: String {
        return "\(self.rawValue.lowercased())_model"
    }
}

// MARK: - View Model Data
struct DrumModel: Identifiable {
    let id = UUID()
    let type: DrumType
    let iconName: String
}
