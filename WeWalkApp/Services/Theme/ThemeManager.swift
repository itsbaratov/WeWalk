//
//  ThemeManager.swift
//  WeWalkApp
//
//  Manages app theme (light/dark/system) with persistence
//

import UIKit
import Combine

enum AppTheme: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
    
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return .unspecified
        }
    }
}

final class ThemeManager {
    
    static let shared = ThemeManager()
    
    // MARK: - Properties
    
    private let userDefaultsKey = "appTheme"
    
    @Published private(set) var currentTheme: AppTheme
    
    // MARK: - Init
    
    private init() {
        let savedTheme = UserDefaults.standard.string(forKey: userDefaultsKey) ?? AppTheme.system.rawValue
        self.currentTheme = AppTheme(rawValue: savedTheme) ?? .system
    }
    
    // MARK: - Public Methods
    
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: userDefaultsKey)
        applyTheme()
    }
    
    func applyTheme() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        
        for window in windowScene.windows {
            window.overrideUserInterfaceStyle = currentTheme.userInterfaceStyle
        }
    }
    
    func applyTheme(to window: UIWindow?) {
        window?.overrideUserInterfaceStyle = currentTheme.userInterfaceStyle
    }
}
