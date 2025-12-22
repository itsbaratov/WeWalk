//
//  TreePlantingCoordinator.swift
//  WeWalkApp
//
//  Coordinates the drag-and-drop tree planting flow
//

import UIKit

protocol TreePlantingCoordinatorDelegate: AnyObject {
    func coordinatorDidConfirmPlanting(at slot: PlacementSlot, treeData: ReadyTreeData)
    func coordinatorDidCancelPlanting()
}

final class TreePlantingCoordinator: NSObject {
    
    // MARK: - Properties
    
    weak var delegate: TreePlantingCoordinatorDelegate?
    
    private weak var containerView: UIView?
    private weak var canvasView: GardenCanvasView?
    private weak var scrollView: UIScrollView?
    
    private var dragPreview: UIImageView?
    private var currentTreeData: ReadyTreeData?
    private var currentSlot: PlacementSlot?
    
    private var confirmationView: InlinePlantConfirmationView?
    private var temporaryTreeView: UIImageView?
    
    private var gardenGrid: GardenGrid
    
    // MARK: - Init
    
    init(containerView: UIView, canvasView: GardenCanvasView, scrollView: UIScrollView, grid: GardenGrid) {
        self.containerView = containerView
        self.canvasView = canvasView
        self.scrollView = scrollView
        self.gardenGrid = grid
        super.init()
    }
    
    // MARK: - Public Methods
    
    func updateGrid(_ grid: GardenGrid) {
        self.gardenGrid = grid
    }
    
    // MARK: - Drag Handling
    
    func handleDragBegan(from card: DraggableTreeCardView, gesture: UIPanGestureRecognizer) {
        guard let containerView = containerView,
              let treeData = card.treeData else { return }
        
        currentTreeData = treeData
        
        // Create floating preview
        let preview = card.createDragPreview()
        let location = gesture.location(in: containerView)
        preview.center = location
        containerView.addSubview(preview)
        dragPreview = preview
        
        // Initial lift animation
        preview.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            preview.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
    }
    
    func handleDragMoved(gesture: UIPanGestureRecognizer) {
        guard let containerView = containerView,
              let preview = dragPreview,
              let canvasView = canvasView,
              let scrollView = scrollView else { return }
        
        // Move preview with finger
        let location = gesture.location(in: containerView)
        preview.center = location
        
        // Convert to canvas coordinates
        let scrollLocation = gesture.location(in: scrollView)
        let canvasLocation = CGPoint(
            x: (scrollLocation.x + scrollView.contentOffset.x) / scrollView.zoomScale,
            y: (scrollLocation.y + scrollView.contentOffset.y) / scrollView.zoomScale
        )
        
        // Check if we're over the canvas and find nearest slot
        if canvasView.isWithinGrassArea(canvasLocation) {
            if let nearestSlot = gardenGrid.nearestAvailableSlot(to: canvasLocation) {
                canvasView.showHighlight(at: nearestSlot)
                currentSlot = nearestSlot
            }
        } else {
            canvasView.hideHighlight()
            currentSlot = nil
        }
    }
    
    func handleDragEnded(gesture: UIPanGestureRecognizer) {
        guard let canvasView = canvasView else {
            cleanupDrag()
            return
        }
        
        // Hide highlight
        canvasView.hideHighlight()
        
        // Check if we have a valid drop slot
        if let slot = currentSlot, let treeData = currentTreeData {
            showConfirmation(at: slot, for: treeData)
        } else {
            // No valid drop - animate preview back
            animateCancelDrag()
        }
    }
    
    // MARK: - Confirmation Flow
    
    private func showConfirmation(at slot: PlacementSlot, for treeData: ReadyTreeData) {
        guard let containerView = containerView,
              let canvasView = canvasView,
              let scrollView = scrollView,
              let preview = dragPreview else { return }
        
        // Calculate screen position for the slot
        let slotPositionInCanvas = slot.position
        let slotPositionInScrollView = CGPoint(
            x: slotPositionInCanvas.x * scrollView.zoomScale - scrollView.contentOffset.x,
            y: slotPositionInCanvas.y * scrollView.zoomScale - scrollView.contentOffset.y
        )
        let slotPositionInContainer = scrollView.convert(slotPositionInScrollView, to: containerView)
        
        // Animate preview to slot position
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            preview.center = slotPositionInContainer
            preview.transform = .identity
        }
        
        // Create temporary tree on canvas (for visual feedback)
        if let image = treeData.treeType?.image(for: .adult) {
            let tempTree = UIImageView(image: image)
            tempTree.contentMode = .scaleAspectFit
            tempTree.frame = CGRect(
                x: slot.position.x - AppConstants.Garden.treeSize / 2,
                y: slot.position.y - AppConstants.Garden.treeSize,
                width: AppConstants.Garden.treeSize,
                height: AppConstants.Garden.treeSize
            )
            tempTree.alpha = 0.7
            canvasView.addSubview(tempTree)
            temporaryTreeView = tempTree
        }
        
        // Create and show confirmation view
        let confirmation = InlinePlantConfirmationView()
        confirmation.delegate = self
        confirmation.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(confirmation)
        
        // Position confirmation next to the tree
        let confirmX = min(slotPositionInContainer.x + 50, containerView.bounds.width - 60)
        let confirmY = max(slotPositionInContainer.y - 20, 80)
        
        NSLayoutConstraint.activate([
            confirmation.centerXAnchor.constraint(equalTo: containerView.leadingAnchor, constant: confirmX),
            confirmation.centerYAnchor.constraint(equalTo: containerView.topAnchor, constant: confirmY),
            confirmation.widthAnchor.constraint(equalToConstant: 100),
            confirmation.heightAnchor.constraint(equalToConstant: 70)
        ])
        
        containerView.layoutIfNeeded()
        confirmation.show()
        confirmationView = confirmation
        
        // Hide the drag preview (we have the temp tree now)
        UIView.animate(withDuration: 0.2) {
            preview.alpha = 0
        }
    }
    
    // MARK: - Cleanup
    
    private func animateCancelDrag() {
        guard let preview = dragPreview else {
            cleanupDrag()
            return
        }
        
        UIView.animate(withDuration: 0.3, animations: {
            preview.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            preview.alpha = 0
        }) { _ in
            self.cleanupDrag()
        }
    }
    
    private func cleanupDrag() {
        dragPreview?.removeFromSuperview()
        dragPreview = nil
        temporaryTreeView?.removeFromSuperview()
        temporaryTreeView = nil
        currentTreeData = nil
        currentSlot = nil
    }
    
    private func hideConfirmation() {
        confirmationView?.hide { [weak self] in
            self?.confirmationView?.removeFromSuperview()
            self?.confirmationView = nil
        }
    }
}

// MARK: - InlinePlantConfirmationDelegate

extension TreePlantingCoordinator: InlinePlantConfirmationDelegate {
    
    func confirmationViewDidConfirm(_ view: InlinePlantConfirmationView) {
        guard let slot = currentSlot, let treeData = currentTreeData else {
            hideConfirmation()
            cleanupDrag()
            return
        }
        
        // Remove temporary tree (the real one will be added by the view controller)
        temporaryTreeView?.removeFromSuperview()
        temporaryTreeView = nil
        
        hideConfirmation()
        cleanupDrag()
        
        delegate?.coordinatorDidConfirmPlanting(at: slot, treeData: treeData)
    }
    
    func confirmationViewDidCancel(_ view: InlinePlantConfirmationView) {
        hideConfirmation()
        cleanupDrag()
        delegate?.coordinatorDidCancelPlanting()
    }
}
