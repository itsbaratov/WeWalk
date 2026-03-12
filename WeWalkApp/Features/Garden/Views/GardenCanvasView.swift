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

enum SlotState {
    case empty
    case occupied
    case active
}

final class IsometricSlotView: UIView {
    
    override class var layerClass: AnyClass {
        return CAShapeLayer.self
    }
    
    var shapeLayer: CAShapeLayer {
        return layer as! CAShapeLayer
    }
    
    private var currentState: SlotState = .empty
    
    /// The isometric diamond path used for hit testing
    private(set) var diamondPath: CGPath?
    
    // Dashed border layer for empty slots
    private let dashedBorderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.lineDashPattern = [6, 4]
        layer.lineWidth = 1.5
        return layer
    }()
    
    // Inner glow layer for active state
    private let glowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.clear.cgColor
        layer.lineWidth = 0
        return layer
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        backgroundColor = .clear
        layer.addSublayer(dashedBorderLayer)
        layer.addSublayer(glowLayer)
        setState(.empty)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cornerRadius = AppConstants.Garden.slotCornerRadius
        let path = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: bounds.width, height: bounds.width), cornerRadius: cornerRadius)
        
        // Transform the rounded square into an isometric diamond
        var transform = CGAffineTransform.identity
        // 1. Scale down Y by half to flatten it (isometric aspect ratio is 2:1)
        transform = transform.scaledBy(x: 1.0, y: 0.5)
        // 2. Rotate by 45 degrees
        transform = transform.rotated(by: .pi / 4)
        
        path.apply(transform)
        
        // After rotation and scaling, the path's bounding box might have shifted.
        // We need to translate it so its center matches the view's center.
        let pathBounds = path.bounds
        let translation = CGAffineTransform(translationX: (bounds.width - pathBounds.width)/2 - pathBounds.minX,
                                            y: (bounds.height - pathBounds.height)/2 - pathBounds.minY)
        path.apply(translation)
        
        shapeLayer.path = path.cgPath
        dashedBorderLayer.path = path.cgPath
        glowLayer.path = path.cgPath
        diamondPath = path.cgPath
        
        // Update sublayer frames
        dashedBorderLayer.frame = bounds
        glowLayer.frame = bounds
    }
    
    func setState(_ state: SlotState) {
        self.currentState = state
        
        // Stop any running animations first
        layer.removeAllAnimations()
        self.transform = .identity
        
        switch state {
        case .empty:
            shapeLayer.fillColor = UIColor.white.withAlphaComponent(0.10).cgColor
            shapeLayer.strokeColor = UIColor.clear.cgColor
            shapeLayer.lineWidth = 0
            
            // Dashed border for empty slots — invites interaction
            dashedBorderLayer.strokeColor = UIColor.white.withAlphaComponent(0.40).cgColor
            dashedBorderLayer.lineWidth = 1.5
            dashedBorderLayer.isHidden = false
            
            glowLayer.isHidden = true
            
        case .occupied:
            shapeLayer.fillColor = UIColor.black.withAlphaComponent(0.06).cgColor
            shapeLayer.strokeColor = UIColor.clear.cgColor
            shapeLayer.lineWidth = 0
            
            dashedBorderLayer.isHidden = true
            glowLayer.isHidden = true
            
        case .active:
            shapeLayer.fillColor = UIColor.appMintGreen.withAlphaComponent(0.35).cgColor
            shapeLayer.strokeColor = UIColor.appMintGreen.cgColor
            shapeLayer.lineWidth = 2.5
            
            dashedBorderLayer.isHidden = true
            
            // Outer glow effect
            glowLayer.isHidden = false
            glowLayer.strokeColor = UIColor.appMintGreen.withAlphaComponent(0.25).cgColor
            glowLayer.lineWidth = 6
            
            // Smooth pulse animation
            let pulse = CABasicAnimation(keyPath: "opacity")
            pulse.fromValue = 1.0
            pulse.toValue = 0.5
            pulse.duration = 0.8
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            glowLayer.add(pulse, forKey: "glowPulse")
        }
    }
    
    /// Check if a point (in this view's coordinate system) is within the isometric diamond
    func containsPoint(_ point: CGPoint) -> Bool {
        guard let path = diamondPath else { return false }
        return path.contains(point)
    }
}

final class GardenCanvasView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: GardenCanvasViewDelegate?
    
    private var treeViews: [UUID: UIImageView] = [:]
    private var slotViews: [UUID: IsometricSlotView] = [:]
    private var slotData: [UUID: PlacementSlot] = [:]
    private var highlightedSlot: PlacementSlot?
    private var hasTapGesture = false  // Guard against duplicate gestures
    
    private let groundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "new_ground")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
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
        
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(
            width: AppConstants.Garden.canvasSize,
            height: AppConstants.Garden.canvasSize
        )
    }
    
    // MARK: - Public Methods
    
    /// Instantiate and lay out the persistent grid of rounded slots based on the provided garden grid.
    func setupGridStyles(grid: GardenGrid) {
        // Clear any existing slot views
        slotViews.values.forEach { $0.removeFromSuperview() }
        slotViews.removeAll()
        slotData.removeAll()
        
        // Use a padded dimension so slots have visual gaps between them
        let padding = AppConstants.Garden.slotPadding
        let slotW = AppConstants.Garden.tileWidth - padding
        let slotH = AppConstants.Garden.tileHeight - padding
        
        for slot in grid.slots.flatMap({ $0 }) {
            let view = IsometricSlotView()
            view.frame = CGRect(
                x: slot.position.x - slotW / 2,
                y: slot.position.y - slotH / 2,
                width: slotW,
                height: slotH
            )
            
            // Set initial state
            view.setState(slot.isOccupied ? .occupied : .empty)
            
            addSubview(view)
            slotViews[slot.id] = view
            slotData[slot.id] = slot
            sendSubviewToBack(view) // Make sure they stay behind trees but in front of ground
        }
        
        sendSubviewToBack(groundImageView)
        
        // Tap gesture to plant — only add once
        if !hasTapGesture {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleCanvasTap(_:)))
            self.addGestureRecognizer(tap)
            self.isUserInteractionEnabled = true
            hasTapGesture = true
        }
        
        sortTreesByDepth()
    }
    
    @objc private func handleCanvasTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        
        // Find which slot was tapped using accurate path-based hit testing
        for (id, slotView) in slotViews {
            let pointInSlot = convert(location, to: slotView)
            
            if slotView.containsPoint(pointInSlot) {
                guard let slot = slotData[id], !slot.isOccupied else { return }
                
                // Brief highlight feedback
                slotView.setState(.active)
                UIView.animate(withDuration: 0.15, delay: 0.1, options: []) {
                    slotView.setState(.empty)
                }
                
                delegate?.gardenCanvas(self, didSelectSlot: slot)
                return
            }
        }
    }
    
    /// Add a tree at a specific grid slot
    func addTree(image: UIImage, at slot: PlacementSlot, treeId: UUID, animated: Bool = true) {
        let treeSize = AppConstants.Garden.treeSize
        
        let treeView = UIImageView(image: image)
        treeView.contentMode = .scaleAspectFit
        treeView.frame = CGRect(
            x: slot.position.x - treeSize / 2,
            y: slot.position.y - treeSize + 15,  // Anchor trunk smoothly
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
        
        // Mark slot as occupied
        if let slotView = slotViews[slot.id] {
            slotView.setState(.occupied)
        }
        
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
    
    /// Animates the specific slot that the tree is hovering over
    func highlightActiveSlot(_ slot: PlacementSlot?) {
        guard slot?.id != highlightedSlot?.id else { return } // No change
        
        // Reset previous active slot to its original state (empty or occupied)
        if let prevSlot = highlightedSlot, let prevView = slotViews[prevSlot.id] {
            prevView.setState(prevSlot.isOccupied ? .occupied : .empty)
        }
        
        highlightedSlot = slot
        
        // Set new active slot
        if let newSlot = slot, let newView = slotViews[newSlot.id] {
            newView.setState(.active)
            bringSubviewToFront(newView)
            
            // Light haptic
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }
    
    /// Hide active slot highlights
    func hideActiveSlotRevertingState() {
        if let currentSlot = highlightedSlot, let currentView = slotViews[currentSlot.id] {
            currentView.setState(currentSlot.isOccupied ? .occupied : .empty)
        }
        highlightedSlot = nil
        sortTreesByDepth()
    }
    
    /// Get the currently highlighted slot
    func getHighlightedSlot() -> PlacementSlot? {
        return highlightedSlot
    }
    
    /// Convert a point from another view to canvas coordinates
    func canvasPoint(from point: CGPoint, in view: UIView) -> CGPoint {
        return convert(point, from: view)
    }
    
    /// Find the slot at a specific canvas point using accurate path hit testing
    func slotAt(canvasPoint point: CGPoint) -> PlacementSlot? {
        for (id, slotView) in slotViews {
            let pointInSlot = convert(point, to: slotView)
            if slotView.containsPoint(pointInSlot) {
                return slotData[id]
            }
        }
        return nil
    }
    
    /// Check if a point is within the plantable grass area
    func isWithinGrassArea(_ point: CGPoint) -> Bool {
        // Define grass area bounds (diamond shape) for 5x5 grid
        let centerX = AppConstants.Garden.grassCenterX
        let centerY: CGFloat = AppConstants.Garden.grassStartY + 80
        
        let halfWidth: CGFloat = 220  // Half width of diamond (grid width ~320 + padding)
        let halfHeight: CGFloat = 120  // Half height of diamond (grid height ~160 + padding)
        
        // Check if point is within the diamond
        let normalizedX = abs(point.x - centerX) / halfWidth
        let normalizedY = abs(point.y - centerY) / halfHeight
        
        return (normalizedX + normalizedY) <= 1.0
    }
    
    // MARK: - Private Methods
    
    private func sortTreesByDepth() {
        // Sort by Y position - lower Y (further back) should be behind
        
        for slotView in slotViews.values {
            sendSubviewToBack(slotView)
        }
        sendSubviewToBack(groundImageView)
        
        let sortedTrees = treeViews.values.sorted { $0.frame.origin.y < $1.frame.origin.y }
        for tree in sortedTrees {
            bringSubviewToFront(tree)
        }
        
        if let activeSlot = highlightedSlot, let activeView = slotViews[activeSlot.id] {
            bringSubviewToFront(activeView)
        }
    }
}
