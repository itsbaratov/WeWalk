//
//  TreeGrowthStage.swift
//  WeWalkApp
//
//  Tree growth stages based on daily step goal progress
//

import Foundation

/// Represents the growth stage of a tree based on daily step progress percentage
enum TreeGrowthStage: Int, CaseIterable, Codable {
    case seed = 0      // 0-19%
    case sprout = 1    // 20-39%
    case young = 2     // 40-59%
    case mature = 3    // 60-79%
    case adult = 4     // 80-100% (Ready to plant)
    
    /// Get the stage for a given progress percentage (0.0 to 1.0+)
    static func forProgress(_ progress: Double) -> TreeGrowthStage {
        switch progress {
        case ..<AppConstants.TreeGrowth.seedMaxProgress:
            return .seed
        case ..<AppConstants.TreeGrowth.sproutMaxProgress:
            return .sprout
        case ..<AppConstants.TreeGrowth.youngMaxProgress:
            return .young
        case ..<AppConstants.TreeGrowth.matureMaxProgress:
            return .mature
        default:
            return .adult
        }
    }
    
    /// Display name for the growth stage
    var displayName: String {
        switch self {
        case .seed: return "Seed"
        case .sprout: return "Sprout"
        case .young: return "Young Tree"
        case .mature: return "Mature Tree"
        case .adult: return "Adult Tree"
        }
    }
    
    /// Whether this tree is ready to be planted in the garden
    var isReadyToPlant: Bool {
        self == .adult
    }
    
    /// Asset suffix for this growth stage
    var assetSuffix: String {
        switch self {
        case .seed: return "seed"
        case .sprout: return "sprout"
        case .young: return "young"
        case .mature: return "mature"
        case .adult: return "adult"
        }
    }
    
    /// Progress range description
    var progressRange: String {
        switch self {
        case .seed: return "0-19%"
        case .sprout: return "20-39%"
        case .young: return "40-59%"
        case .mature: return "60-79%"
        case .adult: return "80-100%"
        }
    }
}
