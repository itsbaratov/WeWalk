//
//  HealthKitService.swift
//  WeWalkApp
//
//  HealthKit integration for step tracking
//

import Foundation
import HealthKit
import Combine

// MARK: - Protocol

protocol HealthKitServiceProtocol {
    var isAuthorized: Bool { get }
    
    func requestAuthorization() async throws -> Bool
    func fetchTodaySteps() async throws -> Int
    func fetchTodayDistance() async throws -> Double
    func fetchTodayCalories() async throws -> Double
    func fetchSteps(for dateRange: ClosedRange<Date>) async throws -> [Date: Int]
    func fetchHourlySteps(for date: Date) async throws -> [Int: Int]
    func startObservingSteps(handler: @escaping (Int) -> Void)
    func stopObservingSteps()
}

// MARK: - Errors

enum HealthKitError: Error, LocalizedError {
    case notAvailable
    case authorizationDenied
    case dataNotAvailable
    case queryFailed(Error)
    
    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit is not available on this device"
        case .authorizationDenied:
            return "HealthKit authorization was denied"
        case .dataNotAvailable:
            return "Health data is not available"
        case .queryFailed(let error):
            return "Query failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Implementation

final class HealthKitService: HealthKitServiceProtocol {
    
    private let healthStore = HKHealthStore()
    private var stepObserverQuery: HKObserverQuery?
    private var stepAnchorQuery: HKAnchoredObjectQuery?
    
    // MARK: - Types
    
    private lazy var stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    private lazy var distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    private lazy var caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
    
    private var typesToRead: Set<HKObjectType> {
        [stepType, distanceType, caloriesType]
    }
    
    // MARK: - Authorization
    
    var isAuthorized: Bool {
        guard HKHealthStore.isHealthDataAvailable() else { 
            print("[HealthKit] Health data not available on this device")
            return false 
        }
        // Note: For read-only permissions, iOS doesn't reveal authorization status for privacy
        // We return true and let queries fail gracefully if not authorized
        return true
    }
    
    func requestAuthorization() async throws -> Bool {
        print("[HealthKit] Checking if HealthKit is available...")
        
        guard HKHealthStore.isHealthDataAvailable() else {
            print("[HealthKit] HealthKit NOT available on this device")
            throw HealthKitError.notAvailable
        }
        
        print("[HealthKit] HealthKit is available, requesting authorization...")
        print("[HealthKit] Types to read: \(typesToRead)")
        
        return try await withCheckedThrowingContinuation { continuation in
            healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
                if let error = error {
                    print("[HealthKit] Authorization error: \(error.localizedDescription)")
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                } else {
                    print("[HealthKit] Authorization completed. Success: \(success)")
                    // Note: 'success' only indicates the prompt was shown, not that permission was granted
                    // For read permissions, iOS always returns true to protect user privacy
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    // MARK: - Today's Data
    
    func fetchTodaySteps() async throws -> Int {
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: today, options: .strictStartDate)
        
        return try await fetchSum(for: stepType, predicate: predicate, unit: .count())
    }
    
    func fetchTodayDistance() async throws -> Double {
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: today, options: .strictStartDate)
        
        return try await fetchSumDouble(for: distanceType, predicate: predicate, unit: .meter())
    }
    
    func fetchTodayCalories() async throws -> Double {
        let today = Date()
        let startOfDay = Calendar.current.startOfDay(for: today)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: today, options: .strictStartDate)
        
        return try await fetchSumDouble(for: caloriesType, predicate: predicate, unit: .kilocalorie())
    }
    
    // MARK: - Historical Data
    
    func fetchSteps(for dateRange: ClosedRange<Date>) async throws -> [Date: Int] {
        let predicate = HKQuery.predicateForSamples(
            withStart: dateRange.lowerBound.startOfDay,
            end: dateRange.upperBound.endOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: dateRange.lowerBound.startOfDay,
                intervalComponents: DateComponents(day: 1)
            )
            
            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let results = results else {
                    continuation.resume(returning: [:])
                    return
                }
                
                var stepsPerDay: [Date: Int] = [:]
                
                results.enumerateStatistics(
                    from: dateRange.lowerBound.startOfDay,
                    to: dateRange.upperBound.endOfDay
                ) { statistics, _ in
                    let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    stepsPerDay[statistics.startDate] = Int(steps)
                }
                
                continuation.resume(returning: stepsPerDay)
            }
            
            healthStore.execute(query)
        }
    }
    
    func fetchHourlySteps(for date: Date) async throws -> [Int: Int] {
        let startOfDay = date.startOfDay
        let endOfDay = date.endOfDay
        
        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: stepType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startOfDay,
                intervalComponents: DateComponents(hour: 1)
            )
            
            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                guard let results = results else {
                    continuation.resume(returning: [:])
                    return
                }
                
                var stepsPerHour: [Int: Int] = [:]
                
                results.enumerateStatistics(from: startOfDay, to: endOfDay) { statistics, _ in
                    let hour = Calendar.current.component(.hour, from: statistics.startDate)
                    let steps = statistics.sumQuantity()?.doubleValue(for: .count()) ?? 0
                    stepsPerHour[hour] = Int(steps)
                }
                
                continuation.resume(returning: stepsPerHour)
            }
            
            healthStore.execute(query)
        }
    }
    
    // MARK: - Observation
    
    func startObservingSteps(handler: @escaping (Int) -> Void) {
        print("[HealthKit] Starting step observation...")
        
        let query = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("[HealthKit] Observer query error: \(error.localizedDescription)")
                return
            }
            
            Task {
                do {
                    let steps = try await self?.fetchTodaySteps() ?? 0
                    await MainActor.run {
                        handler(steps)
                    }
                } catch {
                    print("[HealthKit] Error fetching steps in observer: \(error)")
                }
            }
        }
        
        stepObserverQuery = query
        healthStore.execute(query)
        
        // Enable background delivery
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if let error = error {
                print("[HealthKit] Background delivery error: \(error)")
            } else {
                print("[HealthKit] Background delivery enabled: \(success)")
            }
        }
    }
    
    func stopObservingSteps() {
        if let query = stepObserverQuery {
            healthStore.stop(query)
            stepObserverQuery = nil
            print("[HealthKit] Stopped step observation")
        }
    }
    
    // MARK: - Helpers
    
    private func fetchSum(for type: HKQuantityType, predicate: NSPredicate, unit: HKUnit) async throws -> Int {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("[HealthKit] Query error for \(type): \(error.localizedDescription)")
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: Int(value))
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchSumDouble(for type: HKQuantityType, predicate: NSPredicate, unit: HKUnit) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                if let error = error {
                    print("[HealthKit] Query error for \(type): \(error.localizedDescription)")
                    continuation.resume(throwing: HealthKitError.queryFailed(error))
                    return
                }
                
                let value = result?.sumQuantity()?.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            
            healthStore.execute(query)
        }
    }
}
