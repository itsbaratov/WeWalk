//
//  StatsViewModel.swift
//  WeWalkApp
//
//  ViewModel for Stats screen
//

import Foundation
import Combine

enum TimeRange: String, CaseIterable {
    case weekly = "Weekly"
    case monthly = "Monthly" 
    case yearly = "Yearly"
}

final class StatsViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var selectedTimeRange: TimeRange = .weekly
    @Published var chartData: [ChartDataPoint] = []
    @Published var hourlyData: [Int: Int] = [:]
    
    @Published var averageDaily: Int = 0
    @Published var averageWeekly: Int = 0
    @Published var totalMonthly: Int = 0
    @Published var totalYearly: Int = 0
    
    @Published var isLoading: Bool = false
    
    // MARK: - Services
    
    private let healthKitService: HealthKitServiceProtocol
    
    // MARK: - Init
    
    init(healthKitService: HealthKitServiceProtocol = HealthKitService()) {
        self.healthKitService = healthKitService
        super.init()
    }
    
    override func setupBindings() {
        $selectedTimeRange
            .sink { [weak self] range in
                Task {
                    await self?.loadData(for: range)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Data Loading
    
    func loadInitialData() async {
        await loadData(for: selectedTimeRange)
        await loadAverages()
        await loadHourlyData()
    }
    
    private func loadData(for timeRange: TimeRange) async {
        await MainActor.run { self.isLoading = true }
        
        let endDate = Date()
        let startDate: Date
        
        switch timeRange {
        case .weekly:
            startDate = endDate.adding(days: -6)
        case .monthly:
            startDate = endDate.adding(days: -29)
        case .yearly:
            startDate = endDate.adding(months: -11).startOfMonth
        }
        
        do {
            let stepsData = try await healthKitService.fetchSteps(for: startDate...endDate)
            
            await MainActor.run {
                self.chartData = self.processChartData(stepsData: stepsData, timeRange: timeRange)
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.isLoading = false
            }
        }
    }
    
    private func loadAverages() async {
        let today = Date()
        
        do {
            // Last 7 days
            let weekData = try await healthKitService.fetchSteps(for: today.adding(days: -6)...today)
            let weekTotal = weekData.values.reduce(0, +)
            
            // Last 30 days
            let monthData = try await healthKitService.fetchSteps(for: today.adding(days: -29)...today)
            let monthTotal = monthData.values.reduce(0, +)
            
            // Last 365 days
            let yearData = try await healthKitService.fetchSteps(for: today.adding(days: -364)...today)
            let yearTotal = yearData.values.reduce(0, +)
            
            await MainActor.run {
                self.averageDaily = weekTotal / 7
                self.averageWeekly = weekTotal
                self.totalMonthly = monthTotal
                self.totalYearly = yearTotal
            }
        } catch {
            // Handle error silently
        }
    }
    
    private func loadHourlyData() async {
        do {
            let hourly = try await healthKitService.fetchHourlySteps(for: Date())
            await MainActor.run {
                self.hourlyData = hourly
            }
        } catch {
            // Handle error silently
        }
    }
    
    private func processChartData(stepsData: [Date: Int], timeRange: TimeRange) -> [ChartDataPoint] {
        var points: [ChartDataPoint] = []
        let dailyGoal = UserDefaults.standard.integer(forKey: "dailyGoal")
        let goal = dailyGoal > 0 ? dailyGoal : AppConstants.DailyGoal.defaultSteps
        
        switch timeRange {
        case .weekly, .monthly:
            let sortedDates = stepsData.keys.sorted()
            for date in sortedDates {
                let steps = stepsData[date] ?? 0
                let label = timeRange == .weekly ? date.weekdayShort : date.dayMonth
                let progress = Double(steps) / Double(goal)
                points.append(ChartDataPoint(label: label, value: steps, progress: progress))
            }
        case .yearly:
            // Group by month
            var monthlySteps: [String: Int] = [:]
            for (date, steps) in stepsData {
                let monthLabel = date.monthShort
                monthlySteps[monthLabel, default: 0] += steps
            }
            
            // Sort by month order
            let calendar = Calendar.current
            let today = Date()
            for i in 0..<12 {
                let monthDate = calendar.date(byAdding: .month, value: -11 + i, to: today)!
                let label = monthDate.monthShort
                let steps = monthlySteps[label] ?? 0
                points.append(ChartDataPoint(label: label, value: steps, progress: 1.0))
            }
        }
        
        return points
    }
}

// MARK: - Chart Data Point

struct ChartDataPoint: Identifiable {
    let id = UUID()
    let label: String
    let value: Int
    let progress: Double
    
    var color: WeeklyStepData.ProgressCategory {
        if progress >= 1.0 {
            return .success
        } else if progress >= 0.5 {
            return .warning
        } else {
            return .risk
        }
    }
}
