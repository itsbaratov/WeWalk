//
//  HomeCoordinator.swift
//  WeWalkApp
//
//  Coordinator for Home tab
//

import UIKit

protocol HomeCoordinatorDelegate: AnyObject {
    func homeCoordinatorDidRequestTreePicker(_ coordinator: HomeCoordinator)
    func homeCoordinatorDidRequestBadges(_ coordinator: HomeCoordinator)
}

final class HomeCoordinator: BaseCoordinator {
    
    weak var delegate: HomeCoordinatorDelegate?
    
    override func start() {
        let viewModel = HomeViewModel()
        let viewController = HomeViewController(viewModel: viewModel)
        viewController.coordinator = self
        
        navigationController.setNavigationBarHidden(true, animated: false)
        navigationController.pushViewController(viewController, animated: false)
    }
    
    // MARK: - Navigation
    
    func showTreePicker(currentTreeType: String, onSelect: @escaping (String) -> Void) {
        let pickerVC = TreePickerViewController(
            selectedTreeType: currentTreeType,
            onSelect: { [weak self] treeType in
                onSelect(treeType)
                self?.navigationController.dismiss(animated: true)
            }
        )
        
        let nav = UINavigationController(rootViewController: pickerVC)
        if let sheet = nav.sheetPresentationController {
            // Open at large detent (~80% height) by default
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        navigationController.present(nav, animated: true)
    }
    
    func showProgressAndBadges() {
        let badgesVC = ProgressBadgesViewController()
        
        let nav = UINavigationController(rootViewController: badgesVC)
        if let sheet = nav.sheetPresentationController {
            sheet.detents = [.large()]
            sheet.prefersGrabberVisible = true
        }
        
        navigationController.present(nav, animated: true)
    }
}
