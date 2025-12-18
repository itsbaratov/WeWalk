//
//  StatsCoordinator.swift
//  WeWalkApp
//
//  Coordinator for Stats tab
//

import UIKit

final class StatsCoordinator: BaseCoordinator {
    
    override func start() {
        let viewModel = StatsViewModel()
        let viewController = StatsViewController(viewModel: viewModel)
        viewController.coordinator = self
        
        navigationController.setNavigationBarHidden(false, animated: false)
        navigationController.navigationBar.prefersLargeTitles = false
        navigationController.pushViewController(viewController, animated: false)
    }
    
    // MARK: - Navigation
    
    func showDayDetail(date: Date) {
        // TODO: Implement day detail view for hourly breakdown
    }
}
