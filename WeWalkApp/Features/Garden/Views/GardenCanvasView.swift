//
//  GardenCanvasView.swift
//  WeWalkApp
//
//  Isometric garden canvas with ground image and tree placement grid
//

import UIKit

protocol GardenCanvasViewDelegate: AnyObject {
    func gardenCanvas(_ canvas: GardenCanvasView, didSelectSlot slot: PlacementSlot)
}

final class GardenCanvasView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: GardenCanvasViewDelegate?
    
    private var treeViews: [UUID: UIImageView] = [:]
    private var slotIndicators: [UIView] = []
    private var highlightedSlot: PlacementSlot?
    
    private let groundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "ground")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let highlightView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.appMintGreen.withAlphaComponent(0.4)
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 2
        view.layer.borderColor = UIColor.appMintGreen.cgColor
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        backgroundColor = .clear
        
        // Add ground image
        addSubview(groundImageView)
        NSLayoutConstraint.activate([
            groundImageView.topAnchor.constraint(equalTo: topAnchor),
            groundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            groundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            groundImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Add highlight view for drop target
        addSubview(highlightView)
        NSLayoutConstraint.activate([
            highlightView.widthAnchor.constraint(equalToConstant: 60),
            highlightView.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(
            width: AppConstants.Garden.canvasSize,
            height: AppConstants.Garden.canvasSize
        )
    }
    
    // MARK: - Public Methods
    
    /// Add a tree at a specific grid slot
    func addTree(image: UIImage, at slot: PlacementSlot, treeId: UUID, animated: Bool = true) {
        let treeSize = AppConstants.Garden.treeSize
        
        let treeView = UIImageView(image: image)
        treeView.contentMode = .scaleAspectFit
        treeView.frame = CGRect(
            x: slot.position.x - treeSize / 2,
            y: slot.position.y - treeSize,  // Anchor at bottom of tree
            width: treeSize,
            height: treeSize
        )
        
        // Shadow for depth
        treeView.layer.shadowColor = UIColor.black.cgColor
        treeView.layer.shadowOffset = CGSize(width: 0, height: 4)
        treeView.layer.shadowRadius = 8
        treeView.layer.shadowOpacity = 0.3
        
        if animated {
            treeView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            treeView.alpha = 0
        }
        
        addSubview(treeView)
        treeViews[treeId] = treeView
        
        // Sort trees by Y position (back to front)
        sortTreesByDepth()
        
        if animated {
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
                treeView.transform = .identity
                treeView.alpha = 1
            }
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }
    
    /// Remove a tree by ID
    func removeTree(id: UUID, animated: Bool = true) {
        guard let treeView = treeViews[id] else { return }
        
        if animated {
            UIView.animate(withDuration: 0.3, animations: {
                treeView.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
                treeView.alpha = 0
            }) { _ in
                treeView.removeFromSuperview()
            }
        } else {
            treeView.removeFromSuperview()
        }
        
        treeViews.removeValue(forKey: id)
    }
    
    /// Clear all trees
    func clearTrees() {
        treeViews.values.forEach { $0.removeFromSuperview() }
        treeViews.removeAll()
    }
    
    /// Show highlight at a specific slot (during drag)
    func showHighlight(at slot: PlacementSlot?) {
        guard let slot = slot else {
            highlightView.isHidden = true
            highlightedSlot = nil
            return
        }
        
        highlightedSlot = slot
        highlightView.isHidden = false
        highlightView.center = slot.position
        bringSubviewToFront(highlightView)
        
        // Pulse animation
        UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse]) {
            self.highlightView.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
        }
        
        // Light haptic
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    /// Hide the highlight
    func hideHighlight() {
        highlightView.isHidden = true
        highlightView.layer.removeAllAnimations()
        highlightView.transform = .identity
        highlightedSlot = nil
    }
    
    /// Get the currently highlighted slot
    func getHighlightedSlot() -> PlacementSlot? {
        return highlightedSlot
    }
    
    /// Convert a point from another view to canvas coordinates
    func canvasPoint(from point: CGPoint, in view: UIView) -> CGPoint {
        return convert(point, from: view)
    }
    
    /// Check if a point is within the plantable grass area
    func isWithinGrassArea(_ point: CGPoint) -> Bool {
        // Define grass area bounds (diamond shape)
        let centerX = AppConstants.Garden.grassCenterX
        let centerY: CGFloat = 350  // Approximate center of grass
        let halfWidth: CGFloat = 400  // Half width of diamond
        let halfHeight: CGFloat = 200  // Half height of diamond
        
        // Check if point is within the diamond
        let normalizedX = abs(point.x - centerX) / halfWidth
        let normalizedY = abs(point.y - centerY) / halfHeight
        
        return (normalizedX + normalizedY) <= 1.0
    }
    
    // MARK: - Private Methods
    
    private func sortTreesByDepth() {
        // Sort by Y position - lower Y (further back) should be behind
        let sortedTrees = treeViews.values.sorted { $0.frame.origin.y < $1.frame.origin.y }
        for tree in sortedTrees {
            bringSubviewToFront(tree)
        }
        // Ensure highlight stays on top
        bringSubviewToFront(highlightView)
    }
}
