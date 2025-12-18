//
//  ProfileViewModel.swift
//  WeWalkApp
//
//  ViewModel for Profile screen
//

import Foundation
import Combine

final class ProfileViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var dailyGoal: Int = AppConstants.DailyGoal.defaultSteps
    @Published var redeemedTrees: [RedeemedTree] = []
    @Published var archivedGardens: [ArchivedGarden] = []
    
    // MARK: - Init
    
    override init() {
        super.init()
        loadSettings()
        loadMockData()
    }
    
    // MARK: - Data Loading
    
    private func loadSettings() {
        if let savedGoal = UserDefaults.standard.object(forKey: "dailyGoal") as? Int {
            dailyGoal = savedGoal
        }
    }
    
    private func loadMockData() {
        // Mock redeemed trees
        redeemedTrees = [
            RedeemedTree(id: UUID(), providerName: "One Tree Planted", location: "WI, Banora", date: Date().adding(days: -30)),
            RedeemedTree(id: UUID(), providerName: "One Tree Planted", location: "CA, USA", date: Date().adding(days: -60))
        ]
        
        // Mock archived gardens
        archivedGardens = [
            ArchivedGarden(id: UUID(), name: "Eternal Grove", status: .complete, treeCount: 30),
            ArchivedGarden(id: UUID(), name: "Legacy Forest", status: .complete, treeCount: 30),
            ArchivedGarden(id: UUID(), name: "Traded Canopies", status: .redeemed, treeCount: 30)
        ]
    }
    
    // MARK: - Actions
    
    func updateDailyGoal(_ goal: Int) {
        dailyGoal = goal
        UserDefaults.standard.set(goal, forKey: "dailyGoal")
    }
}

// MARK: - Data Models

struct RedeemedTree: Identifiable {
    let id: UUID
    let providerName: String
    let location: String
    let date: Date
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct ArchivedGarden: Identifiable {
    let id: UUID
    let name: String
    let status: GardenStatus
    let treeCount: Int
}
