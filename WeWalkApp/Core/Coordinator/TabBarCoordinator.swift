//
//  TabBarCoordinator.swift
//  WeWalkApp
//
//  Main tab bar coordinator managing the 4 main screens
//

import UIKit

final class TabBarCoordinator: BaseCoordinator {
    
    private let tabBarController: UITabBarController
    
    // Child coordinators for each tab
    private var homeCoordinator: HomeCoordinator?
    private var gardenCoordinator: GardenCoordinator?
    private var statsCoordinator: StatsCoordinator?
    private var profileCoordinator: ProfileCoordinator?
    
    init(tabBarController: UITabBarController = UITabBarController()) {
        self.tabBarController = tabBarController
        super.init(navigationController: UINavigationController())
    }
    
    override func start() {
        setupTabBar()
        setupTabs()
    }
    
    private func setupTabBar() {
        // Create transparent tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        
        // Configure for both light and dark modes using dynamic colors
        appearance.stackedLayoutAppearance.normal.iconColor = .appTabBarUnselected
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.appTabBarUnselected
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = .appTabBarSelected
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.appTabBarSelected
        ]
        
        tabBarController.tabBar.standardAppearance = appearance
        if #available(iOS 15.0, *) {
            tabBarController.tabBar.scrollEdgeAppearance = appearance
        }
        
        // Ensure proper tint colors for iOS 26 compatibility
        tabBarController.tabBar.tintColor = .appTabBarSelected
        tabBarController.tabBar.unselectedItemTintColor = .appTabBarUnselected
    }
    
    private func setupTabs() {
        // Home Tab
        let homeNav = UINavigationController()
        homeNav.isNavigationBarHidden = true
        homeNav.tabBarItem = UITabBarItem(
            title: "Home",
            image: UIImage(systemName: "house"),
            selectedImage: UIImage(systemName: "house.fill")
        )
        let homeCoord = HomeCoordinator(navigationController: homeNav)
        addChild(homeCoord)
        homeCoord.start()
        self.homeCoordinator = homeCoord
        
        // Garden Tab
        let gardenNav = UINavigationController()
        gardenNav.isNavigationBarHidden = true
        gardenNav.tabBarItem = UITabBarItem(
            title: "Garden",
            image: UIImage(systemName: "leaf"),
            selectedImage: UIImage(systemName: "leaf.fill")
        )
        let gardenCoord = GardenCoordinator(navigationController: gardenNav)
        addChild(gardenCoord)
        gardenCoord.start()
        self.gardenCoordinator = gardenCoord
        
        // Stats Tab
        let statsNav = UINavigationController()
        statsNav.isNavigationBarHidden = true
        statsNav.tabBarItem = UITabBarItem(
            title: "Stats",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )
        let statsCoord = StatsCoordinator(navigationController: statsNav)
        addChild(statsCoord)
        statsCoord.start()
        self.statsCoordinator = statsCoord
        
        // Profile Tab
        let profileNav = UINavigationController()
        profileNav.isNavigationBarHidden = true
        profileNav.tabBarItem = UITabBarItem(
            title: "Profile",
            image: UIImage(systemName: "person"),
            selectedImage: UIImage(systemName: "person.fill")
        )
        let profileCoord = ProfileCoordinator(navigationController: profileNav)
        addChild(profileCoord)
        profileCoord.start()
        self.profileCoordinator = profileCoord
        
        tabBarController.viewControllers = [homeNav, gardenNav, statsNav, profileNav]
    }
    
    func getTabBarController() -> UITabBarController {
        return tabBarController
    }
}
