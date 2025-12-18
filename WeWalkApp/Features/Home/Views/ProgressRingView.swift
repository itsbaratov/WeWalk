//
//  ProgressRingView.swift
//  WeWalkApp
//
//  Circular progress ring for displaying step goal progress
//

import UIKit

final class ProgressRingView: UIView {
    
    // MARK: - Properties
    
    private var progress: CGFloat = 0 {
        didSet {
            updateProgress(animated: true)
        }
    }
    
    private let backgroundLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    private let secondaryProgressLayer = CAShapeLayer()
    
    // Configuration - Increased line width for bolder appearance
    var lineWidth: CGFloat = 16 {
        didSet { setupLayers() }
    }
    
    var backgroundStrokeColor: UIColor = .appTealAccent.withAlphaComponent(0.3) {
        didSet { backgroundLayer.strokeColor = backgroundStrokeColor.cgColor }
    }
    
    var progressStrokeColor: UIColor = .appMintGreen {
        didSet { progressLayer.strokeColor = progressStrokeColor.cgColor }
    }
    
    var secondaryStrokeColor: UIColor = .appSeafoam.withAlphaComponent(0.5) {
        didSet { secondaryProgressLayer.strokeColor = secondaryStrokeColor.cgColor }
    }
    
    // Arc configuration - 3/4 circle (270 degrees)
    private let arcStartAngle: CGFloat = .pi * 0.75    // 135° - bottom left
    private let arcEndAngle: CGFloat = .pi * 2.25      // 405° (45° + 360°) - bottom right, going clockwise
    private let totalArcAngle: CGFloat = .pi * 1.5     // 270° total arc
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupPaths()
    }
    
    // MARK: - Setup
    
    private func setupLayers() {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }
        
        // Background ring
        backgroundLayer.fillColor = UIColor.clear.cgColor
        backgroundLayer.strokeColor = backgroundStrokeColor.cgColor
        backgroundLayer.lineWidth = lineWidth
        backgroundLayer.lineCap = .round
        layer.addSublayer(backgroundLayer)
        
        // Secondary progress (creates depth effect)
        secondaryProgressLayer.fillColor = UIColor.clear.cgColor
        secondaryProgressLayer.strokeColor = secondaryStrokeColor.cgColor
        secondaryProgressLayer.lineWidth = lineWidth + 4
        secondaryProgressLayer.lineCap = .round
        secondaryProgressLayer.strokeEnd = 0
        layer.addSublayer(secondaryProgressLayer)
        
        // Main progress ring
        progressLayer.fillColor = UIColor.clear.cgColor
        progressLayer.strokeColor = progressStrokeColor.cgColor
        progressLayer.lineWidth = lineWidth
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
        
        setupPaths()
    }
    
    private func setupPaths() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = (min(bounds.width, bounds.height) - lineWidth) / 2
        
        // 3/4 circle arc: starts at bottom-left, ends at bottom-right (270° arc)
        let path = UIBezierPath(
            arcCenter: center,
            radius: radius,
            startAngle: arcStartAngle,
            endAngle: arcEndAngle,
            clockwise: true
        )
        
        backgroundLayer.path = path.cgPath
        progressLayer.path = path.cgPath
        secondaryProgressLayer.path = path.cgPath
    }
    
    // MARK: - Public Methods
    
    func setProgress(_ progress: CGFloat, animated: Bool = true) {
        self.progress = min(max(progress, 0), 1.0) // Cap at 100% for visual
        
        if animated {
            updateProgress(animated: true)
        } else {
            CATransaction.begin()
            CATransaction.setDisableActions(true)
            progressLayer.strokeEnd = self.progress
            secondaryProgressLayer.strokeEnd = self.progress  // Synced with main
            CATransaction.commit()
        }
    }
    
    private func updateProgress(animated: Bool) {
        if animated {
            // Animate main progress
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = progressLayer.strokeEnd
            animation.toValue = progress
            animation.duration = AppConstants.Animation.progressRing
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            animation.fillMode = .forwards
            animation.isRemovedOnCompletion = false
            progressLayer.add(animation, forKey: "progressAnimation")
            
            // Animate secondary progress - synced with main (glow effect)
            let secondaryAnimation = CABasicAnimation(keyPath: "strokeEnd")
            secondaryAnimation.fromValue = secondaryProgressLayer.strokeEnd
            secondaryAnimation.toValue = progress  // Same as main progress
            secondaryAnimation.duration = AppConstants.Animation.progressRing * 0.8
            secondaryAnimation.beginTime = CACurrentMediaTime() + 0.1
            secondaryAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            secondaryAnimation.fillMode = .forwards
            secondaryAnimation.isRemovedOnCompletion = false
            secondaryProgressLayer.add(secondaryAnimation, forKey: "secondaryProgressAnimation")
        } else {
            progressLayer.strokeEnd = progress
            secondaryProgressLayer.strokeEnd = progress  // Same as main progress
        }
    }
    
    // MARK: - Visual Effects
    
    func addGlowEffect() {
        progressLayer.shadowColor = progressStrokeColor.cgColor
        progressLayer.shadowOffset = .zero
        progressLayer.shadowRadius = 8
        progressLayer.shadowOpacity = 0.6
    }
    
    func applyGradient(colors: [UIColor]) {
        // Create gradient layer for progress
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = bounds
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        
        // Use progress layer as mask
        gradientLayer.mask = progressLayer
        layer.addSublayer(gradientLayer)
    }
}
