//
//  AppCoordinator.swift
//  WeWalkApp
//
//  Root coordinator that manages app navigation and flow
//

import UIKit

final class AppCoordinator: BaseCoordinator {
    
    private let window: UIWindow
    private var tabBarCoordinator: TabBarCoordinator?
    private var onboardingCoordinator: OnboardingCoordinator?
    
    // Services (injected to child coordinators)
    private lazy var healthKitService: HealthKitServiceProtocol = HealthKitService()
    private lazy var coreDataManager = CoreDataManager.shared
    
    init(window: UIWindow) {
        self.window = window
        super.init(navigationController: UINavigationController())
    }
    
    override func start() {
        // Check if onboarding is completed
        if UserDefaults.standard.bool(forKey: "onboardingCompleted") {
            showMainApp()
        } else {
            showOnboarding()
        }
    }
    
    // MARK: - Navigation
    
    private func showOnboarding() {
        let onboardingNav = UINavigationController()
        onboardingNav.setNavigationBarHidden(true, animated: false)
        
        let onboardingCoord = OnboardingCoordinator(navigationController: onboardingNav)
        onboardingCoord.delegate = self
        addChild(onboardingCoord)
        onboardingCoord.start()
        
        self.onboardingCoordinator = onboardingCoord
        window.rootViewController = onboardingNav
        window.makeKeyAndVisible()
    }
    
    func showMainApp() {
        // Remove onboarding coordinator if exists
        if let onboardingCoord = onboardingCoordinator {
            childDidFinish(onboardingCoord)
            onboardingCoordinator = nil
        }
        
        // Create and show tab bar
        let tabBarCoord = TabBarCoordinator()
        addChild(tabBarCoord)
        tabBarCoord.start()
        
        self.tabBarCoordinator = tabBarCoord
        
        // Animate transition from onboarding
        UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve) {
            self.window.rootViewController = tabBarCoord.getTabBarController()
        }
        
        window.makeKeyAndVisible()
    }
}

// MARK: - OnboardingCoordinatorDelegate

extension AppCoordinator: OnboardingCoordinatorDelegate {
    func onboardingDidComplete() {
        UserDefaults.standard.set(true, forKey: "onboardingCompleted")
        showMainApp()
    }
}
