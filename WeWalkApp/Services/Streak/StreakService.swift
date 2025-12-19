//
//  StreakService.swift
//  WeWalkApp
//
//  Service for tracking and managing streak data
//

import Foundation
import Combine

// MARK: - Protocol

protocol StreakServiceProtocol {
    var currentStreak: CurrentValueSubject<StreakData, Never> { get }
    
    func updateStreak(for date: Date, goalMet: Bool)
    func checkAndRecoverStreak()
    func getUnlockedBadges() -> [BadgeMilestone]
    func getNextBadge() -> BadgeMilestone?
}

// MARK: - Streak Data

struct StreakData {
    let currentStreak: Int
    let longestStreak: Int
    let lastCompletedDate: Date?
    let streakStartDate: Date?
    
    var isActiveToday: Bool {
        guard let lastDate = lastCompletedDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }
    
    var isAtRisk: Bool {
        guard let lastDate = lastCompletedDate else { return false }
        return Calendar.current.isDateInYesterday(lastDate)
    }
}

// MARK: - Implementation

final class StreakService: StreakServiceProtocol {
    
    static let shared = StreakService()
    
    let currentStreak = CurrentValueSubject<StreakData, Never>(
        StreakData(currentStreak: 0, longestStreak: 0, lastCompletedDate: nil, streakStartDate: nil)
    )
    
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadStreak()
        
        // Fix for "Midnight Bug": Re-check streak when system date changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDayChange),
            name: .NSCalendarDayChanged,
            object: nil
        )
    }
    
    @objc private func handleDayChange() {
        print("[StreakService] Day changed - re-checking streak status")
        checkAndRecoverStreak()
    }
    
    // MARK: - Streak Management
    
    func updateStreak(for date: Date, goalMet: Bool) {
        var data = currentStreak.value
        
        guard goalMet else { return }
        
        let calendar = Calendar.current
        
        // Check if already completed today
        if let lastDate = data.lastCompletedDate,
           calendar.isDate(lastDate, inSameDayAs: date) {
            return // Already counted today
        }
        
        var newStreak = data.currentStreak
        var newStreakStart = data.streakStartDate
        
        // Check if this continues an existing streak
        if let lastDate = data.lastCompletedDate {
            let daysDiff = calendar.dateComponents([.day], from: lastDate.startOfDay, to: date.startOfDay).day ?? 0
            
            if daysDiff == 1 {
                // Continuing streak
                newStreak += 1
            } else if daysDiff > 1 {
                // Streak broken, start new
                newStreak = 1
                newStreakStart = date
            }
            // daysDiff == 0 shouldn't happen (checked above)
        } else {
            // First day of streak
            newStreak = 1
            newStreakStart = date
        }
        
        let newLongest = max(data.longestStreak, newStreak)
        
        let newData = StreakData(
            currentStreak: newStreak,
            longestStreak: newLongest,
            lastCompletedDate: date,
            streakStartDate: newStreakStart
        )
        
        currentStreak.send(newData)
        saveStreak(newData)
        
        // Check for badge unlocks
        checkBadgeUnlock(streak: newStreak)
    }
    
    func checkAndRecoverStreak() {
        let data = currentStreak.value
        
        guard let lastDate = data.lastCompletedDate else { return }
        
        let calendar = Calendar.current
        let today = Date()
        let daysSinceLastCompletion = calendar.dateComponents([.day], from: lastDate.startOfDay, to: today.startOfDay).day ?? 0
        
        // If more than 1 day has passed, streak is broken
        if daysSinceLastCompletion > 1 {
            let newData = StreakData(
                currentStreak: 0,
                longestStreak: data.longestStreak,
                lastCompletedDate: nil,
                streakStartDate: nil
            )
            
            currentStreak.send(newData)
            saveStreak(newData)
        }
    }
    
    // MARK: - Badges
    
    func getUnlockedBadges() -> [BadgeMilestone] {
        BadgeMilestone.unlockedMilestones(forStreak: currentStreak.value.longestStreak)
    }
    
    func getNextBadge() -> BadgeMilestone? {
        BadgeMilestone.nextMilestone(afterStreak: currentStreak.value.currentStreak)
    }
    
    private func checkBadgeUnlock(streak: Int) {
        // Check if this streak unlocks a new badge
        if let milestone = BadgeMilestone.milestone(forStreak: streak) {
            // Post notification for badge unlock animation
            NotificationCenter.default.post(
                name: .badgeUnlocked,
                object: nil,
                userInfo: ["milestone": milestone]
            )
        }
    }
    
    // MARK: - Persistence
    
    private func loadStreak() {
        let streak = userDefaults.integer(forKey: "currentStreak")
        let longest = userDefaults.integer(forKey: "longestStreak")
        let lastDate = userDefaults.object(forKey: "lastCompletedDate") as? Date
        let startDate = userDefaults.object(forKey: "streakStartDate") as? Date
        
        let data = StreakData(
            currentStreak: streak,
            longestStreak: longest,
            lastCompletedDate: lastDate,
            streakStartDate: startDate
        )
        
        currentStreak.send(data)
        
        // Check if streak needs to be reset
        checkAndRecoverStreak()
    }
    
    private func saveStreak(_ data: StreakData) {
        userDefaults.set(data.currentStreak, forKey: "currentStreak")
        userDefaults.set(data.longestStreak, forKey: "longestStreak")
        userDefaults.set(data.lastCompletedDate, forKey: "lastCompletedDate")
        userDefaults.set(data.streakStartDate, forKey: "streakStartDate")
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let badgeUnlocked = Notification.Name("badgeUnlockedNotification")
}
