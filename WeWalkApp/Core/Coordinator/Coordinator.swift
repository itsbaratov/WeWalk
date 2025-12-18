//
//  Coordinator.swift
//  WeWalkApp
//
//  MVVM+Coordinator base protocol
//

import UIKit

// MARK: - Coordinator Protocol

protocol Coordinator: AnyObject {
    var navigationController: UINavigationController { get set }
    var childCoordinators: [Coordinator] { get set }
    var parentCoordinator: Coordinator? { get set }
    
    func start()
    func childDidFinish(_ child: Coordinator)
}

// MARK: - Default Implementation

extension Coordinator {
    func childDidFinish(_ child: Coordinator) {
        for (index, coordinator) in childCoordinators.enumerated() {
            if coordinator === child {
                childCoordinators.remove(at: index)
                break
            }
        }
    }
    
    func addChild(_ coordinator: Coordinator) {
        childCoordinators.append(coordinator)
        coordinator.parentCoordinator = self
    }
    
    func removeAllChildren() {
        childCoordinators.removeAll()
    }
}

// MARK: - Base Coordinator Class

class BaseCoordinator: Coordinator {
    var navigationController: UINavigationController
    var childCoordinators: [Coordinator] = []
    weak var parentCoordinator: Coordinator?
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        fatalError("start() must be implemented by subclass")
    }
}
