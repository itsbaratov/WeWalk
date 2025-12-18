//
//  GardenCoordinator.swift
//  WeWalkApp
//
//  Coordinator for Garden tab
//

import UIKit

final class GardenCoordinator: BaseCoordinator {
    
    override func start() {
        let viewModel = GardenViewModel()
        let viewController = GardenViewController(viewModel: viewModel)
        viewController.coordinator = self
        
        navigationController.setNavigationBarHidden(false, animated: false)
        navigationController.navigationBar.prefersLargeTitles = false
        navigationController.pushViewController(viewController, animated: false)
    }
    
    // MARK: - Navigation
    
    func showArchivedGardens() {
        let archivedVC = ArchivedGardensViewController()
        navigationController.pushViewController(archivedVC, animated: true)
    }
    
    func showGardenDetail(garden: GardenEntity) {
        // TODO: Implement garden detail view
    }
}
