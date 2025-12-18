//
//  GardenViewModel.swift
//  WeWalkApp
//
//  ViewModel for Garden screen
//

import UIKit
import Combine

final class GardenViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var plantedTrees: [PlantedTreeData] = []
    @Published var readyToPlantTrees: [ReadyTreeData] = []
    @Published var currentGardenTreeCount: Int = 0
    @Published var gardenStatus: GardenStatus = .active
    
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
    }
    
    // MARK: - Data Loading
    
    private func loadMockData() {
        // For now, create some mock planted trees
        plantedTrees = [
            PlantedTreeData(id: UUID(), treeTypeId: "oak", position: CGPoint(x: 100, y: 150)),
            PlantedTreeData(id: UUID(), treeTypeId: "oak", position: CGPoint(x: 250, y: 200)),
            PlantedTreeData(id: UUID(), treeTypeId: "oak", position: CGPoint(x: 180, y: 320)),
        ]
        currentGardenTreeCount = plantedTrees.count
    }
    
    // MARK: - Actions
    
    func plantTree(at position: CGPoint, treeTypeId: String) {
        let newTree = PlantedTreeData(id: UUID(), treeTypeId: treeTypeId, position: position)
        plantedTrees.append(newTree)
        currentGardenTreeCount = plantedTrees.count
        
        // Check if garden is complete
        if currentGardenTreeCount >= AppConstants.Garden.maxCapacity {
            gardenStatus = .complete
        }
        
        // Remove from ready to plant
        readyToPlantTrees.removeAll { $0.treeTypeId == treeTypeId }
    }
    
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
    
    func getTreeImage(for treeTypeId: String) -> UIImage? {
        treeRegistry.treeType(byId: treeTypeId)?.image(for: .adult)
    }
}

// MARK: - Data Models

struct PlantedTreeData: Identifiable {
    let id: UUID
    let treeTypeId: String
    let position: CGPoint
}

struct ReadyTreeData: Identifiable {
    let id: UUID
    let treeTypeId: String
    let treeType: TreeTypeInfo?
}
