//
//  GardenStatus.swift
//  WeWalkApp
//
//  Garden status enum for tracking garden lifecycle
//

import Foundation

/// Status of a virtual garden
enum GardenStatus: String, CaseIterable, Codable {
    /// Active Garden - in progress, less than 30 trees
    case active = "active"
    
    /// Canopy Complete - exactly 30/30 trees, completion achieved
    case complete = "complete"
    
    /// Memory Grove - archived garden library (user can browse)
    case archived = "archived"
    
    /// Redeemed Grove - traded for real-world tree planting
    case redeemed = "redeemed"
    
    /// Display name for UI
    var displayName: String {
        switch self {
        case .active: return "Active Garden"
        case .complete: return "Canopy Complete"
        case .archived: return "Memory Grove"
        case .redeemed: return "Redeemed Grove"
        }
    }
    
    /// Subtitle for UI
    var subtitle: String {
        switch self {
        case .active: return "In progress"
        case .complete: return "Ready to redeem!"
        case .archived: return "Previous full garden"
        case .redeemed: return "Real trees planted"
        }
    }
    
    /// Whether the garden can accept new trees
    var canPlantTrees: Bool {
        self == .active
    }
    
    /// Whether the garden can be redeemed
    var canBeRedeemed: Bool {
        self == .complete
    }
    
    /// Whether the garden is read-only (archived or redeemed)
    var isReadOnly: Bool {
        self == .archived || self == .redeemed
    }
}
