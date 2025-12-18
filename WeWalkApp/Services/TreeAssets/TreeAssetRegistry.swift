//
//  TreeAssetRegistry.swift
//  WeWalkApp
//
//  Scalable tree asset registry loaded from JSON
//

import UIKit

// MARK: - Tree Type Model

struct TreeTypeInfo: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let rarity: TreeRarity
    let assetPrefix: String
    
    enum TreeRarity: String, Codable {
        case common
        case uncommon
        case rare
        case legendary
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    /// Get asset name for a specific growth stage
    func assetName(for stage: TreeGrowthStage) -> String {
        "\(assetPrefix)_\(stage.assetSuffix)"
    }
    
    /// Get UIImage for a specific growth stage
    func image(for stage: TreeGrowthStage) -> UIImage? {
        UIImage(named: assetName(for: stage))
    }
}

// MARK: - Registry

final class TreeAssetRegistry {
    
    static let shared = TreeAssetRegistry()
    
    private(set) var treeTypes: [TreeTypeInfo] = []
    
    private init() {
        loadTreeTypes()
    }
    
    // MARK: - Loading
    
    private func loadTreeTypes() {
        // First try to load from JSON file
        if let url = Bundle.main.url(forResource: "TreeTypes", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let types = try? JSONDecoder().decode([TreeTypeInfo].self, from: data) {
            self.treeTypes = types
        } else {
            // Fall back to hardcoded defaults
            self.treeTypes = Self.defaultTreeTypes
        }
    }
    
    // MARK: - Accessors
    
    func treeType(byId id: String) -> TreeTypeInfo? {
        treeTypes.first { $0.id == id }
    }
    
    func treeTypes(byRarity rarity: TreeTypeInfo.TreeRarity) -> [TreeTypeInfo] {
        treeTypes.filter { $0.rarity == rarity }
    }
    
    var defaultTreeType: TreeTypeInfo {
        treeTypes.first ?? Self.defaultTreeTypes[0]
    }
    
    // MARK: - Default Tree Types
    
    static let defaultTreeTypes: [TreeTypeInfo] = [
        TreeTypeInfo(
            id: "oak",
            name: "Oak",
            description: "A mighty oak tree, symbol of strength and endurance.",
            rarity: .common,
            assetPrefix: "tree_oak"
        ),
        TreeTypeInfo(
            id: "maple",
            name: "Maple",
            description: "Beautiful maple with vibrant autumn colors.",
            rarity: .common,
            assetPrefix: "tree_maple"
        ),
        TreeTypeInfo(
            id: "pine",
            name: "Pine",
            description: "An evergreen pine that stays green year-round.",
            rarity: .common,
            assetPrefix: "tree_pine"
        ),
        TreeTypeInfo(
            id: "cherry",
            name: "Cherry Blossom",
            description: "Delicate cherry tree with beautiful pink flowers.",
            rarity: .uncommon,
            assetPrefix: "tree_cherry"
        ),
        TreeTypeInfo(
            id: "willow",
            name: "Willow",
            description: "Graceful willow with flowing branches.",
            rarity: .uncommon,
            assetPrefix: "tree_willow"
        ),
        TreeTypeInfo(
            id: "birch",
            name: "Birch",
            description: "Elegant birch with distinctive white bark.",
            rarity: .common,
            assetPrefix: "tree_birch"
        ),
        TreeTypeInfo(
            id: "apple",
            name: "Apple",
            description: "Fruitful apple tree for your garden.",
            rarity: .uncommon,
            assetPrefix: "tree_apple"
        ),
        TreeTypeInfo(
            id: "palm",
            name: "Palm",
            description: "Tropical palm bringing vacation vibes.",
            rarity: .rare,
            assetPrefix: "tree_palm"
        ),
        TreeTypeInfo(
            id: "redwood",
            name: "Redwood",
            description: "Ancient giant from the California forests.",
            rarity: .rare,
            assetPrefix: "tree_redwood"
        ),
        TreeTypeInfo(
            id: "bonsai",
            name: "Bonsai",
            description: "Miniature masterpiece of living art.",
            rarity: .legendary,
            assetPrefix: "tree_bonsai"
        )
    ]
    
    // MARK: - Reload (for future remote updates)
    
    func reload(from data: Data) throws {
        let types = try JSONDecoder().decode([TreeTypeInfo].self, from: data)
        self.treeTypes = types
    }
}
