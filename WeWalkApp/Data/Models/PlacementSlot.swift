//
//  PlacementSlot.swift
//  WeWalkApp
//
//  Model for tracking grid slot state in the garden
//

import Foundation

/// Represents a single placement slot in the garden grid
struct PlacementSlot: Identifiable {
    let id: UUID
    let row: Int
    let col: Int
    var isOccupied: Bool
    var plantedTreeId: UUID?
    var treeTypeId: String?
    
    /// Position on canvas (calculated from grid coordinates)
    var position: CGPoint {
        let tileWidth = AppConstants.Garden.tileWidth
        let tileHeight = AppConstants.Garden.tileHeight
        let centerX = AppConstants.Garden.grassCenterX
        let startY = AppConstants.Garden.grassStartY
        
        // Isometric grid formula: each row staggers horizontally
        let x = centerX + CGFloat(col - 3) * tileWidth + CGFloat(row) * (tileWidth / 2)
        let y = startY + CGFloat(row) * tileHeight
        return CGPoint(x: x, y: y)
    }
    
    init(row: Int, col: Int) {
        self.id = UUID()
        self.row = row
        self.col = col
        self.isOccupied = false
        self.plantedTreeId = nil
        self.treeTypeId = nil
    }
}

/// Grid of placement slots for the garden
struct GardenGrid {
    var slots: [[PlacementSlot]]
    
    init() {
        slots = []
        for row in 0..<AppConstants.Garden.gridRows {
            var rowSlots: [PlacementSlot] = []
            for col in 0..<AppConstants.Garden.gridCols {
                rowSlots.append(PlacementSlot(row: row, col: col))
            }
            slots.append(rowSlots)
        }
    }
    
    /// Total number of occupied slots
    var occupiedCount: Int {
        slots.flatMap { $0 }.filter { $0.isOccupied }.count
    }
    
    /// Check if garden is full
    var isFull: Bool {
        occupiedCount >= AppConstants.Garden.maxCapacity
    }
    
    /// Get all available (unoccupied) slots
    var availableSlots: [PlacementSlot] {
        slots.flatMap { $0 }.filter { !$0.isOccupied }
    }
    
    /// Find the nearest available slot to a given position
    func nearestAvailableSlot(to position: CGPoint) -> PlacementSlot? {
        let available = availableSlots
        guard !available.isEmpty else { return nil }
        
        return available.min { slot1, slot2 in
            let dist1 = hypot(slot1.position.x - position.x, slot1.position.y - position.y)
            let dist2 = hypot(slot2.position.x - position.x, slot2.position.y - position.y)
            return dist1 < dist2
        }
    }
    
    /// Mark a slot as occupied
    mutating func occupySlot(row: Int, col: Int, treeId: UUID, treeTypeId: String) {
        guard row >= 0, row < slots.count,
              col >= 0, col < slots[row].count else { return }
        
        slots[row][col].isOccupied = true
        slots[row][col].plantedTreeId = treeId
        slots[row][col].treeTypeId = treeTypeId
    }
    
    /// Get slot at specific row and column
    func slot(at row: Int, col: Int) -> PlacementSlot? {
        guard row >= 0, row < slots.count,
              col >= 0, col < slots[row].count else { return nil }
        return slots[row][col]
    }
}
