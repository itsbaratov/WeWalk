//
//  OnboardingViewModel.swift
//  WeWalkApp
//
//  ViewModel for Onboarding flow
//

import Foundation
import Combine

final class OnboardingViewModel: BaseViewModel {
    
    @Published var currentStep: OnboardingStep = .welcome
    @Published var dailyGoal: Int = AppConstants.DailyGoal.defaultSteps
    @Published var selectedTreeType: String = "oak"
    
    enum OnboardingStep {
        case welcome
        case permissions
        case goalSetup
        case treeSelection
    }
    
    func saveDailyGoal() {
        UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal")
    }
    
    func saveSelectedTree() {
        UserDefaults.standard.set(selectedTreeType, forKey: "selectedTreeType")
    }
}
