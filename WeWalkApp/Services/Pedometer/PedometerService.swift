//
//  PedometerService.swift
//  WeWalkApp
//
//  Created by WeWalk Team on 2024-12-19.
//

import CoreMotion
import Foundation

protocol PedometerServiceProtocol {
    var isPedometerAvailable: Bool { get }
    func startPedometerUpdates(from date: Date, handler: @escaping (Int, Double) -> Void)
    func stopPedometerUpdates()
}

final class PedometerService: PedometerServiceProtocol {
    
    // MARK: - Properties
    
    private let pedometer = CMPedometer()
    private var isUpdating = false
    
    // MARK: - Protocol Implementation
    
    var isPedometerAvailable: Bool {
        CMPedometer.isStepCountingAvailable()
    }
    
    func startPedometerUpdates(from date: Date, handler: @escaping (Int, Double) -> Void) {
        guard isPedometerAvailable else {
            print("[PedometerService] Step counting is not available on this device.")
            return
        }
        
        guard !isUpdating else { return }
        isUpdating = true
        
        print("[PedometerService] Starting updates from: \(date)")
        
        pedometer.startUpdates(from: date) { [weak self] data, error in
            guard let self = self else { return }
            
            if let error = error {
                print("[PedometerService] Error: \(error.localizedDescription)")
                self.isUpdating = false
                return
            }
            
            if let data = data {
                let steps = data.numberOfSteps.intValue
                let distance = data.distance?.doubleValue ?? 0.0
                print("[PedometerService] Live - Steps: \(steps), Distance: \(distance)")
                handler(steps, distance)
            }
        }
    }
    
    func stopPedometerUpdates() {
        guard isUpdating else { return }
        pedometer.stopUpdates()
        isUpdating = false
        print("[PedometerService] Stopped updates")
    }
}
