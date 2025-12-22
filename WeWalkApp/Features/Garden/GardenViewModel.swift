//
//  GardenViewModel.swift
//  WeWalkApp
//
//  ViewModel for Garden screen with grid-based tree placement
//

import UIKit
import Combine

final class GardenViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var plantedTrees: [PlantedTreeData] = []
    @Published var readyToPlantTrees: [ReadyTreeData] = []
    @Published var currentGardenTreeCount: Int = 0
    @Published var gardenStatus: GardenStatus = .active
    @Published var hasArchivedGardens: Bool = false
    @Published private(set) var gardenGrid: GardenGrid = GardenGrid()
    
    // MARK: - Services
    
    private let treeGrowthService: TreeGrowthServiceProtocol
    private let treeRegistry: TreeAssetRegistry
    
    // MARK: - Init
    
    init(
        treeGrowthService: TreeGrowthServiceProtocol = TreeGrowthService.shared,
        treeRegistry: TreeAssetRegistry = .shared
    ) {
        self.treeGrowthService = treeGrowthService
        self.treeRegistry = treeRegistry
        super.init()
        loadMockData()
        checkForArchivedGardens()
    }
    
    // MARK: - Data Loading
    
    private func loadMockData() {
        // Load existing planted trees and mark their slots as occupied
        // For demo, plant 3 trees at fixed positions
        let mockTrees = [
            (row: 0, col: 2),
            (row: 1, col: 3),
            (row: 2, col: 1)
        ]
        
        for (row, col) in mockTrees {
            let treeId = UUID()
            gardenGrid.occupySlot(row: row, col: col, treeId: treeId, treeTypeId: "oak")
            
            if let slot = gardenGrid.slot(at: row, col: col) {
                plantedTrees.append(PlantedTreeData(
                    id: treeId,
                    treeTypeId: "oak",
                    position: slot.position,
                    row: row,
                    col: col
                ))
            }
        }
        
        currentGardenTreeCount = plantedTrees.count
    }
    
    private func checkForArchivedGardens() {
        // TODO: Check actual data source for archived gardens
        // For now, set to false
        hasArchivedGardens = false
    }
    
    // MARK: - Tree Planting
    
    /// Plant a tree at a specific grid slot
    func plantTree(at slot: PlacementSlot, treeData: ReadyTreeData) {
        guard !gardenGrid.isFull else { return }
        
        let treeId = UUID()
        let treeTypeId = treeData.treeTypeId
        
        // Update grid
        gardenGrid.occupySlot(row: slot.row, col: slot.col, treeId: treeId, treeTypeId: treeTypeId)
        
        // Add to planted trees
        let plantedTree = PlantedTreeData(
            id: treeId,
            treeTypeId: treeTypeId,
            position: slot.position,
            row: slot.row,
            col: slot.col
        )
        plantedTrees.append(plantedTree)
        currentGardenTreeCount = plantedTrees.count
        
        // Remove from ready to plant
        readyToPlantTrees.removeAll { $0.id == treeData.id }
        
        // Check if garden is complete
        if gardenGrid.isFull {
            gardenStatus = .complete
        }
    }
    
    /// Check for trees that are ready to plant (reached adult stage)
    func checkForReadyTrees() {
        if let state = treeGrowthService.currentGrowingTree.value,
           state.isReadyToPlant {
            let readyTree = ReadyTreeData(
                id: UUID(),
                treeTypeId: state.treeTypeId,
                treeType: state.treeType
            )
            if !readyToPlantTrees.contains(where: { $0.treeTypeId == readyTree.treeTypeId }) {
                readyToPlantTrees.append(readyTree)
            }
        }
    }
    
    /// Get tree image for a tree type
    func getTreeImage(for treeTypeId: String) -> UIImage? {
        treeRegistry.treeType(byId: treeTypeId)?.image(for: .adult)
    }
    
    /// Get the current garden grid
    func getGrid() -> GardenGrid {
        return gardenGrid
    }
}

// MARK: - Data Models

struct PlantedTreeData: Identifiable {
    let id: UUID
    let treeTypeId: String
    let position: CGPoint
    let row: Int
    let col: Int
}

struct ReadyTreeData: Identifiable {
    let id: UUID
    let treeTypeId: String
    let treeType: TreeTypeInfo?
}
