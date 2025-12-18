//
//  HomeViewModel.swift
//  WeWalkApp
//
//  ViewModel for Home screen
//

import Foundation
import Combine
import HealthKit

final class HomeViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    
    @Published var steps: Int = 0
    @Published var distance: Double = 0
    @Published var calories: Double = 0
    @Published var progress: Double = 0
    @Published var dailyGoal: Int = AppConstants.DailyGoal.defaultSteps
    
    @Published var currentTreeType: TreeTypeInfo?
    @Published var currentGrowthStage: TreeGrowthStage = .seed
    @Published var isTreeLocked: Bool = false
    @Published var isReadyToPlant: Bool = false
    
    @Published var streakCount: Int = 0
    @Published var weeklyData: [WeeklyStepData.DayStepData] = []
    
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var showHealthKitError: Bool = false
    
    // MARK: - Services
    
    private let healthKitService: HealthKitServiceProtocol
    private let treeGrowthService: TreeGrowthServiceProtocol
    private let streakService: StreakServiceProtocol
    private let treeRegistry: TreeAssetRegistry
    
    // MARK: - Init
    
    init(
        healthKitService: HealthKitServiceProtocol = HealthKitService(),
        treeGrowthService: TreeGrowthServiceProtocol = TreeGrowthService.shared,
        streakService: StreakServiceProtocol = StreakService.shared,
        treeRegistry: TreeAssetRegistry = .shared
    ) {
        self.healthKitService = healthKitService
        self.treeGrowthService = treeGrowthService
        self.streakService = streakService
        self.treeRegistry = treeRegistry
        
        super.init()
        
        loadDailyGoal()
    }
    
    // MARK: - Setup
    
    override func setupBindings() {
        // Bind tree growth state
        treeGrowthService.currentGrowingTree
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.currentTreeType = state?.treeType
                self?.currentGrowthStage = state?.currentStage ?? .seed
                self?.isTreeLocked = state?.isLocked ?? false
                self?.isReadyToPlant = state?.isReadyToPlant ?? false
            }
            .store(in: &cancellables)
        
        // Bind streak data
        streakService.currentStreak
            .receive(on: DispatchQueue.main)
            .map(\.currentStreak)
            .assign(to: &$streakCount)
    }
    
    // MARK: - Data Loading
    
    func requestHealthKitPermission() async {
        print("[HomeViewModel] Requesting HealthKit permission...")
        
        // Check if HealthKit is available first
        guard HKHealthStore.isHealthDataAvailable() else {
            await MainActor.run {
                self.errorMessage = "Health data is not available on this device. Please run on a physical iPhone."
                self.showHealthKitError = true
                self.isLoading = false
            }
            print("[HomeViewModel] HealthKit not available on this device")
            return
        }
        
        do {
            let authorized = try await healthKitService.requestAuthorization()
            print("[HomeViewModel] Authorization result: \(authorized)")
            
            // Always try to load data - user might have granted permission
            await loadTodayData()
            await loadWeeklyData()
            startObservingSteps()
            
        } catch {
            print("[HomeViewModel] Authorization error: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.showHealthKitError = true
                self.isLoading = false
            }
        }
    }
    
    func loadTodayData() async {
        await MainActor.run { self.isLoading = true }
        
        do {
            async let stepsTask = healthKitService.fetchTodaySteps()
            async let distanceTask = healthKitService.fetchTodayDistance()
            async let caloriesTask = healthKitService.fetchTodayCalories()
            
            let (fetchedSteps, fetchedDistance, fetchedCalories) = try await (stepsTask, distanceTask, caloriesTask)
            
            print("[HomeViewModel] Fetched - Steps: \(fetchedSteps), Distance: \(fetchedDistance), Calories: \(fetchedCalories)")
            
            await MainActor.run {
                self.steps = fetchedSteps
                self.distance = fetchedDistance
                self.calories = fetchedCalories
                self.progress = Double(fetchedSteps) / Double(self.dailyGoal)
                self.isLoading = false
                
                // Update tree growth
                self.treeGrowthService.updateTreeProgress(steps: fetchedSteps, goal: self.dailyGoal)
                
                // Check streak
                if self.progress >= 1.0 {
                    self.streakService.updateStreak(for: Date(), goalMet: true)
                }
            }
        } catch {
            print("[HomeViewModel] Error loading today data: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func loadWeeklyData() async {
        let today = Date()
        // Load 30 days of data for scrollable history
        let startDate = today.adding(days: -29)
        
        do {
            let stepsData = try await healthKitService.fetchSteps(for: startDate...today)
            
            await MainActor.run {
                var days: [WeeklyStepData.DayStepData] = []
                
                for dayOffset in 0..<30 {
                    let date = startDate.adding(days: dayOffset)
                    let dayStart = date.startOfDay
                    let daySteps = stepsData[dayStart] ?? 0
                    let goalProgress = Double(daySteps) / Double(self.dailyGoal)
                    
                    days.append(WeeklyStepData.DayStepData(
                        date: date,
                        steps: daySteps,
                        goalProgress: goalProgress
                    ))
                }
                
                self.weeklyData = days
            }
        } catch {
            print("[HomeViewModel] Error loading weekly data: \(error.localizedDescription)")
            await MainActor.run {
                self.errorMessage = error.localizedDescription
            }
        }
    }

    
    private func startObservingSteps() {
        healthKitService.startObservingSteps { [weak self] steps in
            guard let self = self else { return }
            self.steps = steps
            self.progress = Double(steps) / Double(self.dailyGoal)
            self.treeGrowthService.updateTreeProgress(steps: steps, goal: self.dailyGoal)
            
            if self.progress >= 1.0 {
                self.streakService.updateStreak(for: Date(), goalMet: true)
            }
        }
    }
    
    // MARK: - Tree Actions
    
    func selectTree(_ treeTypeId: String) {
        _ = treeGrowthService.selectTreeType(treeTypeId)
    }
    
    var canChangeTree: Bool {
        !isTreeLocked && progress < 1.0
    }
    
    var availableTreeTypes: [TreeTypeInfo] {
        treeRegistry.treeTypes
    }
    
    // MARK: - Goal
    
    private func loadDailyGoal() {
        if let savedGoal = UserDefaults.standard.object(forKey: "dailyGoal") as? Int {
            dailyGoal = savedGoal
        }
    }
    
    func updateDailyGoal(_ newGoal: Int) {
        dailyGoal = newGoal
        UserDefaults.standard.set(newGoal, forKey: "dailyGoal")
        progress = Double(steps) / Double(dailyGoal)
        treeGrowthService.updateTreeProgress(steps: steps, goal: dailyGoal)
    }
    
    // MARK: - Formatting
    
    var formattedSteps: String {
        NumberFormatter.localizedString(from: NSNumber(value: steps), number: .decimal)
    }
    
    var formattedDistance: String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        }
        return String(format: "%.0f m", distance)
    }
    
    var formattedCalories: String {
        String(format: "%.0f kcal", calories)
    }
    
    var progressPercentage: String {
        String(format: "%.0f%% Daily Goal", min(progress * 100, 999))
    }
}
