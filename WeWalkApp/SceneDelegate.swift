//
//  SceneDelegate.swift
//  WeWalkApp
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        // Create window
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // Apply saved theme on launch
        ThemeManager.shared.applyTheme(to: window)
        
        // Create and start app coordinator
        appCoordinator = AppCoordinator(window: window)
        appCoordinator?.start()
    }

    func sceneDidDisconnect(_ scene: UIScene) {}

    func sceneDidBecomeActive(_ scene: UIScene) {}

    func sceneWillResignActive(_ scene: UIScene) {}

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Re-apply theme when returning to foreground
        ThemeManager.shared.applyTheme(to: window)
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Save Core Data context when entering background
        CoreDataManager.shared.saveContext()
    }
}
