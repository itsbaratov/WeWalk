//
//  ProfileCoordinator.swift
//  WeWalkApp
//
//  Coordinator for Profile tab
//

import UIKit

final class ProfileCoordinator: BaseCoordinator {
    
    override func start() {
        let viewModel = ProfileViewModel()
        let viewController = ProfileViewController(viewModel: viewModel)
        viewController.coordinator = self
        
        navigationController.setNavigationBarHidden(false, animated: false)
        navigationController.navigationBar.prefersLargeTitles = false
        navigationController.pushViewController(viewController, animated: false)
    }
    
    // MARK: - Navigation
    
    func showSettings() {
        let settingsVC = SettingsViewController()
        navigationController.pushViewController(settingsVC, animated: true)
    }
    
    func showRedeemedTreeDetail(orderRef: String) {
        // TODO: Implement redeemed tree detail view
    }
    
    func showArchivedGardenDetail(garden: GardenEntity) {
        // TODO: Implement archived garden detail view
    }
}
