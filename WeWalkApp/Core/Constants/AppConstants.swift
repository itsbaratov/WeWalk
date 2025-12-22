//
//  AppConstants.swift
//  WeWalkApp
//
//  App-wide constants and configuration
//

import Foundation

enum AppConstants {
    
    // MARK: - Daily Goal
    
    enum DailyGoal {
        static let defaultSteps: Int = 10000
        static let minimumSteps: Int = 1000
        static let maximumSteps: Int = 50000
        static let stepIncrement: Int = 500
    }
    
    // MARK: - Tree Growth Stages
    
    /// Progress thresholds for tree growth stages (percentage of daily goal)
    enum TreeGrowth {
        /// 0-19% = Seed
        static let seedMaxProgress: Double = 0.20
        /// 20-39% = Sprout
        static let sproutMaxProgress: Double = 0.40
        /// 40-59% = Young
        static let youngMaxProgress: Double = 0.60
        /// 60-79% = Mature
        static let matureMaxProgress: Double = 0.80
        /// 80-100% = Adult (Ready to plant)
        static let adultProgress: Double = 1.0
    }
    
    // MARK: - Garden
    
    enum Garden {
        /// Maximum trees in one garden
        static let maxCapacity: Int = 30
        
        /// Grid dimensions (6 columns × 5 rows = 30 slots)
        static let gridRows: Int = 5
        static let gridCols: Int = 6
        
        /// Isometric tile dimensions
        static let tileWidth: CGFloat = 140
        static let tileHeight: CGFloat = 70
        
        /// Canvas size (matches ground image)
        static let canvasSize: CGFloat = 1024
        
        /// Grass surface positioning
        static let grassCenterX: CGFloat = 512
        static let grassStartY: CGFloat = 180
        
        /// Zoom levels
        static let minZoomScale: CGFloat = 0.5
        static let maxZoomScale: CGFloat = 2.0
        static let defaultZoomScale: CGFloat = 1.0
        
        /// Tree image size on canvas
        static let treeSize: CGFloat = 80
    }
    
    // MARK: - Streak Badges
    
    /// Milestone days for badge unlocks
    static let streakMilestones: [Int] = [
        3,    // Warm Start
        5,    // Rhythm Found
        7,    // First Week
        14,   // Two-Week Flow
        21,   // Habit Seeded
        30,   // Monthly Maker
        40,   // Momentum
        50,   // Half-Century
        60,   // Steady Walker
        75,   // Three-Quarter Mark
        90,   // Season Strong
        100,  // Centurion
        110,  // Overdrive
        125,  // One-Two-Five
        150,  // Trailblazer
        180,  // Six-Month Streak
        200,  // Double Century
        222,  // Triple Two
        250,  // Quarter Thousand
        300,  // Three Hundred Club
        333,  // Triple Three
        365,  // Year Runner-Up
        400,  // Four Hundred Force
        444,  // Triple Four
        500   // Legendary 500
    ]
    
    // MARK: - Charts
    
    enum Charts {
        static let weeklyDaysToShow: Int = 7
        static let monthlyDaysToShow: Int = 30
        static let yearlyMonthsToShow: Int = 12
        
        /// Hours to show in hourly chart (0-23)
        static let hourlyChartHours: ClosedRange<Int> = 0...23
    }
    
    // MARK: - Animation Durations
    
    enum Animation {
        static let quick: Double = 0.2
        static let standard: Double = 0.3
        static let slow: Double = 0.5
        static let progressRing: Double = 1.0
    }
    
    // MARK: - Layout
    
    enum Layout {
        static let standardPadding: CGFloat = 16
        static let smallPadding: CGFloat = 8
        static let largePadding: CGFloat = 24
        
        static let cardCornerRadius: CGFloat = 16
        static let smallCornerRadius: CGFloat = 8
        static let buttonCornerRadius: CGFloat = 12
        
        static let progressRingSize: CGFloat = 250
        static let progressRingLineWidth: CGFloat = 12
        
        static let treeImageSize: CGFloat = 180
    }
    
    // MARK: - HealthKit
    
    enum HealthKit {
        /// How far back to fetch historical data on first launch
        static let historicalDaysToFetch: Int = 365
        
        /// Refresh interval for step updates (seconds)
        static let refreshInterval: TimeInterval = 60
    }
}

extension Notification.Name {
    static let dailyGoalChanged = Notification.Name("dailyGoalChanged")
}
