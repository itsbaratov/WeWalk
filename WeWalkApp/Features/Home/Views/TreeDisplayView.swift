//
//  TreeDisplayView.swift
//  WeWalkApp
//
//  View for displaying the growing tree with animations
//

import UIKit

final class TreeDisplayView: UIView {
    
    // MARK: - UI Elements
    
    private let treeImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let readyBadgeView: UIView = {
        let view = UIView()
        view.backgroundColor = .appMintGreen
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0
        return view
    }()
    
    private let readyLabel: UILabel = {
        let label = UILabel()
        label.text = "Ready to Plant!"
        label.font = .appLabelBold
        label.textColor = .appPrimaryGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // State
    private var currentStage: TreeGrowthStage = .seed
    private var isReadyToPlant: Bool = false
    
    // Tap handler
    var onTap: (() -> Void)?
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        setupGestures()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        addSubview(treeImageView)
        addSubview(readyBadgeView)
        readyBadgeView.addSubview(readyLabel)
        
        NSLayoutConstraint.activate([
            // Tree image - centered and sized
            treeImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            treeImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            treeImageView.widthAnchor.constraint(equalToConstant: AppConstants.Layout.treeImageSize),
            treeImageView.heightAnchor.constraint(equalToConstant: AppConstants.Layout.treeImageSize),
            
            // Ready badge - below tree
            readyBadgeView.centerXAnchor.constraint(equalTo: centerXAnchor),
            readyBadgeView.topAnchor.constraint(equalTo: treeImageView.bottomAnchor, constant: 8),
            readyBadgeView.heightAnchor.constraint(equalToConstant: 24),
            
            // Ready label inside badge
            readyLabel.leadingAnchor.constraint(equalTo: readyBadgeView.leadingAnchor, constant: 12),
            readyLabel.trailingAnchor.constraint(equalTo: readyBadgeView.trailingAnchor, constant: -12),
            readyLabel.centerYAnchor.constraint(equalTo: readyBadgeView.centerYAnchor)
        ])
    }
    
    private func setupGestures() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    
    @objc private func handleTap() {
        // Bounce animation
        UIView.animate(withDuration: 0.1, animations: {
            self.treeImageView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.treeImageView.transform = .identity
            }
        }
        
        onTap?()
    }
    
    // MARK: - Public Methods
    
    func updateTree(treeType: TreeTypeInfo?, stage: TreeGrowthStage, isReady: Bool, animated: Bool = true) {
        let stageChanged = currentStage != stage
        currentStage = stage
        isReadyToPlant = isReady
        
        // Get image for current tree type and stage
        let image: UIImage?
        if let treeType = treeType {
            image = treeType.image(for: stage)
        } else {
            // Fallback to oak tree
            image = UIImage(named: "tree_oak_\(stage.assetSuffix)")
        }
        
        if animated && stageChanged {
            // Animate tree growth
            UIView.animate(withDuration: 0.3, animations: {
                self.treeImageView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
                self.treeImageView.alpha = 0.5
            }) { _ in
                self.treeImageView.image = image
                UIView.animate(withDuration: 0.3) {
                    self.treeImageView.transform = .identity
                    self.treeImageView.alpha = 1.0
                }
            }
        } else {
            treeImageView.image = image
        }
        
        // Show/hide ready badge
        UIView.animate(withDuration: 0.3) {
            self.readyBadgeView.alpha = isReady ? 1 : 0
        }
        
        // Add glow effect when ready
        if isReady {
            addGlowEffect()
        } else {
            removeGlowEffect()
        }
    }
    
    // MARK: - Effects
    
    private func addGlowEffect() {
        treeImageView.layer.shadowColor = UIColor.appMintGreen.cgColor
        treeImageView.layer.shadowOffset = .zero
        treeImageView.layer.shadowRadius = 20
        treeImageView.layer.shadowOpacity = 0.8
        
        // Pulsing animation
        let animation = CABasicAnimation(keyPath: "shadowOpacity")
        animation.fromValue = 0.4
        animation.toValue = 0.8
        animation.duration = 1.5
        animation.autoreverses = true
        animation.repeatCount = .infinity
        treeImageView.layer.add(animation, forKey: "glowPulse")
    }
    
    private func removeGlowEffect() {
        treeImageView.layer.removeAnimation(forKey: "glowPulse")
        treeImageView.layer.shadowOpacity = 0
    }
    
    // MARK: - Animations
    
    func playPlantingAnimation(completion: @escaping () -> Void) {
        UIView.animate(withDuration: 0.3, animations: {
            self.treeImageView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            self.treeImageView.alpha = 0
        }) { _ in
            completion()
        }
    }
    
    func resetAfterPlanting() {
        treeImageView.transform = .identity
        treeImageView.alpha = 1
    }
}
