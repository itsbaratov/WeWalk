//
//  HealthKitModels.swift
//  WeWalkApp
//
//  Models for HealthKit data
//

import Foundation

/// Daily activity summary from HealthKit
struct DailyActivityData {
    let date: Date
    let steps: Int
    let distance: Double  // in meters
    let calories: Double  // in kcal
    
    /// Progress towards daily goal (0.0 to 1.0+)
    func progress(towards goal: Int) -> Double {
        guard goal > 0 else { return 0 }
        return Double(steps) / Double(goal)
    }
    
    /// Distance formatted for display
    var formattedDistance: String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
    
    /// Calories formatted for display
    var formattedCalories: String {
        String(format: "%.0f kcal", calories)
    }
}

/// Weekly step data for chart display
struct WeeklyStepData {
    let days: [DayStepData]
    
    struct DayStepData: Identifiable {
        let id = UUID()
        let date: Date
        let steps: Int
        let goalProgress: Double  // 0.0 to 1.0+
        
        var dayLabel: String {
            date.weekdayShort
        }
        
        var dateLabel: String {
            date.dayMonth
        }
        
        /// Color category based on goal progress
        var progressCategory: ProgressCategory {
            if goalProgress >= 1.0 {
                return .success
            } else if goalProgress >= 0.5 {
                return .warning
            } else {
                return .risk
            }
        }
    }
    
    enum ProgressCategory {
        case success  // 100%+
        case warning  // 50-99%
        case risk     // <50%
    }
}

/// Hourly step breakdown for detailed charts
struct HourlyStepData {
    let date: Date
    let hourlySteps: [Int: Int]  // Hour (0-23) to step count
    
    /// Get steps for a specific hour
    func steps(forHour hour: Int) -> Int {
        hourlySteps[hour] ?? 0
    }
    
    /// Maximum steps in any hour (for chart scaling)
    var maxHourlySteps: Int {
        hourlySteps.values.max() ?? 0
    }
    
    /// Total steps for the day
    var totalSteps: Int {
        hourlySteps.values.reduce(0, +)
    }
}
