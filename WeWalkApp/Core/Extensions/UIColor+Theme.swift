//
//  UIColor+Theme.swift
//  WeWalkApp
//
//  App color palette with dark mode support using dynamic colors
//

import UIKit

extension UIColor {
    
    // MARK: - Primary Colors
    
    /// Deep green background - #1C3D2C (light) / #0A1A12 (dark)
    static var appPrimaryGreen: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "#0A1A12")
                : UIColor(hex: "#1C3D2C")
        }
    }
    
    /// Darker green for gradients - #0F2318 (light) / #050D09 (dark)
    static var appDarkGreen: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "#050D09")
                : UIColor(hex: "#0F2318")
        }
    }
    
    /// Teal accent - #2A5A4A (light) / #1A3A2A (dark)
    static var appTealAccent: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "#1A3A2A")
                : UIColor(hex: "#2A5A4A")
        }
    }
    
    // MARK: - Accent Colors (same in both modes - bright accents)
    
    /// Mint green for progress/success - #9FD8B7
    static let appMintGreen = UIColor(hex: "#9FD8B7")
    
    /// Lighter mint for highlights - #B8E5C9
    static let appLightMint = UIColor(hex: "#B8E5C9")
    
    /// Seafoam for secondary elements - #7FCAA8
    static let appSeafoam = UIColor(hex: "#7FCAA8")
    
    // MARK: - Status Colors (same in both modes)
    
    /// Success (100%+ goal) - Vibrant Green
    static let appStatusSuccess = UIColor(hex: "#4CAF50")
    
    /// Warning (50-99% goal) - Orange
    static let appStatusWarning = UIColor(hex: "#FF9800")
    
    /// Risk (<50% goal) - Soft Red
    static let appStatusRisk = UIColor(hex: "#EF5350")
    
    // MARK: - Surface Colors
    
    /// Page background - Slightly grayish to differentiate from cards
    static var appPageBackground: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "#121212")  // Very dark
                : UIColor(hex: "#F2F2F7")  // iOS system group background
        }
    }
    
    /// Card background - White (light) / Dark Graphite (dark)
    static var appCardBackground: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "#1C1C1E")  // iOS-style dark background
                : UIColor.white
        }
    }
    
    /// Card shadow
    static var appCardShadow: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.black.withAlphaComponent(0.3)
                : UIColor.black.withAlphaComponent(0.1)
        }
    }
    
    /// Subtle divider
    static var appDivider: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "#3A3A3C")
                : UIColor(hex: "#E5E5E5")
        }
    }
    
    // MARK: - Text Colors
    
    /// Primary text on dark background
    static let appTextOnDark = UIColor.white
    
    /// Secondary text on dark background
    static let appSecondaryTextOnDark = UIColor.white.withAlphaComponent(0.7)
    
    /// Primary text on light background (adapts to dark mode)
    static var appTextOnLight: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white
                : UIColor(hex: "#1C1C1E")
        }
    }
    
    /// Secondary text on light background (adapts to dark mode)
    static var appSecondaryTextOnLight: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.6)
                : UIColor(hex: "#8E8E93")
        }
    }
    
    /// Tab bar selected color - adapts to dark mode
    static var appTabBarSelected: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white
                : UIColor(hex: "#1C3D2C")  // appPrimaryGreen in light mode
        }
    }
    
    /// Tab bar unselected color - adapts to dark mode
    static var appTabBarUnselected: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor.white.withAlphaComponent(0.4)
                : UIColor(hex: "#1C3D2C").withAlphaComponent(0.5)
        }
    }
    
    // MARK: - Gradient Colors
    
    /// Main background gradient colors (adapts to dark mode)
    static var appBackgroundGradientColors: [CGColor] {
        // For gradient, we need to manually check current trait collection
        let isDark = UITraitCollection.current.userInterfaceStyle == .dark
        if isDark {
            return [
                UIColor(hex: "#050D09").cgColor,
                UIColor(hex: "#0A1A12").cgColor,
                UIColor(hex: "#1A3A2A").cgColor
            ]
        } else {
            return [
                UIColor(hex: "#0F2318").cgColor,
                UIColor(hex: "#1C3D2C").cgColor,
                UIColor(hex: "#2A5A4A").cgColor
            ]
        }
    }
    
    // MARK: - Settings/System Colors
    
    /// Settings background
    static var appSettingsBackground: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "#121212")  // Very dark but not black
                : UIColor.systemGroupedBackground
        }
    }
    
    /// Settings cell background
    static var appSettingsCellBackground: UIColor {
        UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark
                ? UIColor(hex: "#1C1C1E")
                : UIColor.white
        }
    }
}

// MARK: - Hex Color Initializer

extension UIColor {
    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    convenience init(hex: String, alpha: CGFloat) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)
        
        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: r, green: g, blue: b, alpha: alpha)
    }
}
