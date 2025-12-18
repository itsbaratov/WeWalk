//
//  TreeGrowthService.swift
//  WeWalkApp
//
//  Service for managing tree growth logic
//

import Foundation
import Combine

// MARK: - Protocol

protocol TreeGrowthServiceProtocol {
    var currentGrowingTree: CurrentValueSubject<GrowingTreeState?, Never> { get }
    
    func calculateGrowthStage(steps: Int, goal: Int) -> TreeGrowthStage
    func updateTreeProgress(steps: Int, goal: Int)
    func selectTreeType(_ treeTypeId: String) -> Bool
    func lockTree()
    func plantTree() -> PlantedTreeInfo?
}

// MARK: - Growing Tree State

struct GrowingTreeState {
    let treeTypeId: String
    let treeType: TreeTypeInfo?
    let startDate: Date
    let currentStage: TreeGrowthStage
    let progress: Double
    let isLocked: Bool
    
    var isReadyToPlant: Bool {
        currentStage == .adult && isLocked
    }
    
    var canChangeType: Bool {
        !isLocked && progress < 1.0
    }
}

// MARK: - Planted Tree Info

struct PlantedTreeInfo {
    let id: UUID
    let treeTypeId: String
    let plantedAt: Date
}

// MARK: - Implementation

final class TreeGrowthService: TreeGrowthServiceProtocol {
    
    static let shared = TreeGrowthService()
    
    let currentGrowingTree = CurrentValueSubject<GrowingTreeState?, Never>(nil)
    
    private let coreDataManager = CoreDataManager.shared
    private let treeRegistry = TreeAssetRegistry.shared
    
    private init() {
        loadCurrentGrowingTree()
    }
    
    // MARK: - Growth Calculation
    
    func calculateGrowthStage(steps: Int, goal: Int) -> TreeGrowthStage {
        guard goal > 0 else { return .seed }
        let progress = Double(steps) / Double(goal)
        return TreeGrowthStage.forProgress(progress)
    }
    
    // MARK: - Tree Updates
    
    func updateTreeProgress(steps: Int, goal: Int) {
        guard var state = currentGrowingTree.value else {
            // Create new tree if none exists
            createNewTree(treeTypeId: treeRegistry.defaultTreeType.id)
            return
        }
        
        let progress = Double(steps) / Double(goal)
        let newStage = calculateGrowthStage(steps: steps, goal: goal)
        
        // Check if tree should be locked (reached 100%)
        var shouldLock = state.isLocked
        if !shouldLock && progress >= 1.0 {
            shouldLock = true
        }
        
        let updatedState = GrowingTreeState(
            treeTypeId: state.treeTypeId,
            treeType: state.treeType,
            startDate: state.startDate,
            currentStage: newStage,
            progress: progress,
            isLocked: shouldLock
        )
        
        currentGrowingTree.send(updatedState)
        saveCurrentGrowingTree(updatedState)
    }
    
    func selectTreeType(_ treeTypeId: String) -> Bool {
        guard let state = currentGrowingTree.value,
              state.canChangeType,
              let newTreeType = treeRegistry.treeType(byId: treeTypeId) else {
            return false
        }
        
        let updatedState = GrowingTreeState(
            treeTypeId: treeTypeId,
            treeType: newTreeType,
            startDate: state.startDate,
            currentStage: state.currentStage,
            progress: state.progress,
            isLocked: state.isLocked
        )
        
        currentGrowingTree.send(updatedState)
        saveCurrentGrowingTree(updatedState)
        
        return true
    }
    
    func lockTree() {
        guard var state = currentGrowingTree.value, !state.isLocked else { return }
        
        let updatedState = GrowingTreeState(
            treeTypeId: state.treeTypeId,
            treeType: state.treeType,
            startDate: state.startDate,
            currentStage: state.currentStage,
            progress: state.progress,
            isLocked: true
        )
        
        currentGrowingTree.send(updatedState)
        saveCurrentGrowingTree(updatedState)
    }
    
    func plantTree() -> PlantedTreeInfo? {
        guard let state = currentGrowingTree.value,
              state.isReadyToPlant else {
            return nil
        }
        
        let plantedTree = PlantedTreeInfo(
            id: UUID(),
            treeTypeId: state.treeTypeId,
            plantedAt: Date()
        )
        
        // Reset growing tree for next day
        createNewTree(treeTypeId: treeRegistry.defaultTreeType.id)
        
        return plantedTree
    }
    
    // MARK: - Private Helpers
    
    private func createNewTree(treeTypeId: String) {
        let treeType = treeRegistry.treeType(byId: treeTypeId)
        
        let state = GrowingTreeState(
            treeTypeId: treeTypeId,
            treeType: treeType,
            startDate: Date(),
            currentStage: .seed,
            progress: 0,
            isLocked: false
        )
        
        currentGrowingTree.send(state)
        saveCurrentGrowingTree(state)
    }
    
    private func loadCurrentGrowingTree() {
        // Load from UserDefaults for quick access
        if let data = UserDefaults.standard.data(forKey: "currentGrowingTree"),
           let stored = try? JSONDecoder().decode(StoredGrowingTree.self, from: data) {
            
            // Check if it's a new day - reset tree if so
            if !Calendar.current.isDateInToday(stored.startDate) {
                createNewTree(treeTypeId: stored.treeTypeId)
                return
            }
            
            let treeType = treeRegistry.treeType(byId: stored.treeTypeId)
            let state = GrowingTreeState(
                treeTypeId: stored.treeTypeId,
                treeType: treeType,
                startDate: stored.startDate,
                currentStage: TreeGrowthStage(rawValue: stored.stageRaw) ?? .seed,
                progress: stored.progress,
                isLocked: stored.isLocked
            )
            
            currentGrowingTree.send(state)
        } else {
            // No tree exists, create default
            createNewTree(treeTypeId: treeRegistry.defaultTreeType.id)
        }
    }
    
    private func saveCurrentGrowingTree(_ state: GrowingTreeState) {
        let stored = StoredGrowingTree(
            treeTypeId: state.treeTypeId,
            startDate: state.startDate,
            stageRaw: state.currentStage.rawValue,
            progress: state.progress,
            isLocked: state.isLocked
        )
        
        if let data = try? JSONEncoder().encode(stored) {
            UserDefaults.standard.set(data, forKey: "currentGrowingTree")
        }
    }
}

// MARK: - Storage Model

private struct StoredGrowingTree: Codable {
    let treeTypeId: String
    let startDate: Date
    let stageRaw: Int
    let progress: Double
    let isLocked: Bool
}
