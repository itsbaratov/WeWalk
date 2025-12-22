//
//  DraggableTreeCardView.swift
//  WeWalkApp
//
//  A tree card in the Ready to Plant tray that supports drag gesture
//

import UIKit

protocol DraggableTreeCardDelegate: AnyObject {
    func treeCard(_ card: DraggableTreeCardView, didBeginDragWith gesture: UIPanGestureRecognizer)
    func treeCard(_ card: DraggableTreeCardView, didMoveDragWith gesture: UIPanGestureRecognizer)
    func treeCard(_ card: DraggableTreeCardView, didEndDragWith gesture: UIPanGestureRecognizer)
}

final class DraggableTreeCardView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: DraggableTreeCardDelegate?
    private(set) var treeData: ReadyTreeData?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let treeImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let selectedBorder: CALayer = {
        let layer = CALayer()
        layer.borderColor = UIColor.appMintGreen.cgColor
        layer.borderWidth = 2
        layer.cornerRadius = 12
        layer.isHidden = true
        return layer
    }()
    
    var isDragging: Bool = false {
        didSet {
            updateAppearance()
        }
    }
    
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
        addSubview(containerView)
        containerView.addSubview(treeImageView)
        containerView.layer.addSublayer(selectedBorder)
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            treeImageView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            treeImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
            treeImageView.widthAnchor.constraint(equalToConstant: 50),
            treeImageView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Add pan gesture for dragging
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        isUserInteractionEnabled = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        selectedBorder.frame = containerView.bounds
    }
    
    // MARK: - Configuration
    
    func configure(with treeData: ReadyTreeData) {
        self.treeData = treeData
        treeImageView.image = treeData.treeType?.image(for: .adult)
    }
    
    // MARK: - Appearance
    
    private func updateAppearance() {
        if isDragging {
            // Fade when being dragged
            alpha = 0.5
            selectedBorder.isHidden = false
        } else {
            alpha = 1.0
            selectedBorder.isHidden = true
        }
    }
    
    // MARK: - Gesture Handling
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            isDragging = true
            delegate?.treeCard(self, didBeginDragWith: gesture)
            
            // Haptic
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            
        case .changed:
            delegate?.treeCard(self, didMoveDragWith: gesture)
            
        case .ended, .cancelled:
            isDragging = false
            delegate?.treeCard(self, didEndDragWith: gesture)
            
        default:
            break
        }
    }
    
    // MARK: - Preview Image
    
    /// Create a floating preview image for dragging
    func createDragPreview() -> UIImageView {
        let preview = UIImageView(image: treeImageView.image)
        preview.contentMode = .scaleAspectFit
        preview.frame = CGRect(x: 0, y: 0, width: 80, height: 80)
        
        // Add shadow for depth
        preview.layer.shadowColor = UIColor.black.cgColor
        preview.layer.shadowOffset = CGSize(width: 0, height: 8)
        preview.layer.shadowRadius = 16
        preview.layer.shadowOpacity = 0.4
        
        return preview
    }
}
