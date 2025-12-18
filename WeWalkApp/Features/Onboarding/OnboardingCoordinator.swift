//
//  OnboardingCoordinator.swift
//  WeWalkApp
//
//  Coordinator for onboarding flow
//

import UIKit

protocol OnboardingCoordinatorDelegate: AnyObject {
    func onboardingDidComplete()
}

final class OnboardingCoordinator: BaseCoordinator {
    
    weak var delegate: OnboardingCoordinatorDelegate?
    
    override func start() {
        let viewModel = OnboardingViewModel()
        let viewController = OnboardingViewController(viewModel: viewModel)
        viewController.coordinator = self
        
        navigationController.pushViewController(viewController, animated: false)
    }
    
    // MARK: - Flow Steps
    
    func showPermissionsStep() {
        let permissionsVC = PermissionsViewController()
        permissionsVC.coordinator = self
        navigationController.pushViewController(permissionsVC, animated: true)
    }
    
    func showGoalSetupStep() {
        let goalVC = GoalSetupViewController()
        goalVC.coordinator = self
        navigationController.pushViewController(goalVC, animated: true)
    }
    
    func showTreeSelectionStep() {
        let treeVC = TreeSelectionViewController()
        treeVC.coordinator = self
        navigationController.pushViewController(treeVC, animated: true)
    }
    
    func completeOnboarding() {
        delegate?.onboardingDidComplete()
    }
}
