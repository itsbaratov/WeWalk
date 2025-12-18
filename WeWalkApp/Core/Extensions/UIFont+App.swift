//
//  UIFont+App.swift
//  WeWalkApp
//
//  App typography system
//

import UIKit

extension UIFont {
    
    // MARK: - Display Fonts (Large numbers like step count)
    
    /// Extra large step count - 48pt bold
    static let appDisplayLarge = UIFont.systemFont(ofSize: 48, weight: .bold)
    
    /// Large display numbers - 36pt bold
    static let appDisplayMedium = UIFont.systemFont(ofSize: 36, weight: .bold)
    
    /// Medium display - 28pt semibold
    static let appDisplaySmall = UIFont.systemFont(ofSize: 28, weight: .semibold)
    
    // MARK: - Title Fonts
    
    /// Screen titles - 22pt bold
    static let appTitleLarge = UIFont.systemFont(ofSize: 22, weight: .bold)
    
    /// Section titles - 18pt semibold
    static let appTitleMedium = UIFont.systemFont(ofSize: 18, weight: .semibold)
    
    /// Card titles - 16pt semibold
    static let appTitleSmall = UIFont.systemFont(ofSize: 16, weight: .semibold)
    
    // MARK: - Body Fonts
    
    /// Regular body text - 16pt regular
    static let appBodyLarge = UIFont.systemFont(ofSize: 16, weight: .regular)
    
    /// Small body text - 14pt regular
    static let appBodyMedium = UIFont.systemFont(ofSize: 14, weight: .regular)
    
    /// Caption text - 12pt regular
    static let appCaption = UIFont.systemFont(ofSize: 12, weight: .regular)
    
    /// Small caption - 10pt regular
    static let appCaptionSmall = UIFont.systemFont(ofSize: 10, weight: .regular)
    
    // MARK: - Label Fonts
    
    /// Bold labels - 14pt semibold
    static let appLabelBold = UIFont.systemFont(ofSize: 14, weight: .semibold)
    
    /// Medium labels - 14pt medium
    static let appLabelMedium = UIFont.systemFont(ofSize: 14, weight: .medium)
    
    /// Chart labels - 11pt medium
    static let appChartLabel = UIFont.systemFont(ofSize: 14, weight: .medium)
    
    // MARK: - Tab Bar
    
    /// Tab bar labels - 10pt medium
    static let appTabBar = UIFont.systemFont(ofSize: 10, weight: .medium)
}
