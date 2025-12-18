//
//  BadgeMilestone.swift
//  WeWalkApp
//
//  Badge milestone definitions for streak achievements
//

import Foundation

/// Represents a streak badge milestone
struct BadgeMilestone: Codable, Identifiable {
    let id: Int  // The milestone day count
    let name: String
    let description: String
    
    /// All available badge milestones
    static let allMilestones: [BadgeMilestone] = [
        BadgeMilestone(id: 3, name: "Warm Start", description: "Started your walking journey"),
        BadgeMilestone(id: 5, name: "Rhythm Found", description: "Found your daily rhythm"),
        BadgeMilestone(id: 7, name: "First Week", description: "Completed your first week"),
        BadgeMilestone(id: 14, name: "Two-Week Flow", description: "Two weeks of consistency"),
        BadgeMilestone(id: 21, name: "Habit Seeded", description: "A habit is forming"),
        BadgeMilestone(id: 30, name: "Monthly Maker", description: "A full month of steps"),
        BadgeMilestone(id: 40, name: "Momentum", description: "Building unstoppable momentum"),
        BadgeMilestone(id: 50, name: "Half-Century", description: "50 days of dedication"),
        BadgeMilestone(id: 60, name: "Steady Walker", description: "Two months strong"),
        BadgeMilestone(id: 75, name: "Three-Quarter Mark", description: "Three-quarters to 100"),
        BadgeMilestone(id: 90, name: "Season Strong", description: "A full season of walking"),
        BadgeMilestone(id: 100, name: "Centurion", description: "100 days of commitment"),
        BadgeMilestone(id: 110, name: "Overdrive", description: "Going beyond 100"),
        BadgeMilestone(id: 125, name: "One-Two-Five", description: "125 days achieved"),
        BadgeMilestone(id: 150, name: "Trailblazer", description: "Blazing the trail"),
        BadgeMilestone(id: 180, name: "Six-Month Streak", description: "Half a year of steps"),
        BadgeMilestone(id: 200, name: "Double Century", description: "200 days strong"),
        BadgeMilestone(id: 222, name: "Triple Two", description: "The lucky 222"),
        BadgeMilestone(id: 250, name: "Quarter Thousand", description: "250 days achieved"),
        BadgeMilestone(id: 300, name: "Three Hundred Club", description: "Elite walker status"),
        BadgeMilestone(id: 333, name: "Triple Three", description: "The magic 333"),
        BadgeMilestone(id: 365, name: "Year Runner-Up", description: "A full year of walking"),
        BadgeMilestone(id: 400, name: "Four Hundred Force", description: "Unstoppable force"),
        BadgeMilestone(id: 444, name: "Triple Four", description: "The powerful 444"),
        BadgeMilestone(id: 500, name: "Legendary 500", description: "Legendary status achieved")
    ]
    
    /// Get milestone for a specific day count (if it's a milestone day)
    static func milestone(forStreak streak: Int) -> BadgeMilestone? {
        allMilestones.first { $0.id == streak }
    }
    
    /// Get all milestones up to a given streak
    static func unlockedMilestones(forStreak streak: Int) -> [BadgeMilestone] {
        allMilestones.filter { $0.id <= streak }
    }
    
    /// Get next milestone after current streak
    static func nextMilestone(afterStreak streak: Int) -> BadgeMilestone? {
        allMilestones.first { $0.id > streak }
    }
    
    /// Progress to next milestone (0.0 to 1.0)
    static func progressToNextMilestone(currentStreak: Int) -> Double {
        guard let nextMilestone = nextMilestone(afterStreak: currentStreak) else {
            return 1.0 // All milestones achieved
        }
        
        let previousMilestone = allMilestones.last { $0.id <= currentStreak }?.id ?? 0
        let range = Double(nextMilestone.id - previousMilestone)
        let progress = Double(currentStreak - previousMilestone)
        
        return progress / range
    }
}
