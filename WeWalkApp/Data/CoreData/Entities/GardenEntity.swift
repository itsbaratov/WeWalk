//
//  GardenEntity.swift
//  WeWalkApp
//
//  Placeholder for Core Data Garden entity
//

import Foundation

// Placeholder struct - will be replaced by Core Data generated class
struct GardenEntity {
    let id: UUID
    let name: String
    let status: GardenStatus
    let treeCount: Int
    let createdAt: Date
    let completedAt: Date?
    let redeemedAt: Date?
}
