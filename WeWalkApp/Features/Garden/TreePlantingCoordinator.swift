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
    // private weak var scrollView: UIScrollView? // Removed
    
    private var dragPreview: UIImageView?
    private var currentTreeData: ReadyTreeData?
    private var currentSlot: PlacementSlot?
    
    private var confirmationView: InlinePlantConfirmationView?
    private var temporaryTreeView: UIImageView?
    
    private var gardenGrid: GardenGrid
    
    // MARK: - Init
    
    init(containerView: UIView, canvasView: GardenCanvasView, grid: GardenGrid) {
        self.containerView = containerView
        self.canvasView = canvasView
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
        
        // The slots are now persistently shown, so we don't need to call showAvailableSlots anymore.
    }
    
    func handleDragMoved(gesture: UIPanGestureRecognizer) {
        guard let containerView = containerView,
              let preview = dragPreview,
              let canvasView = canvasView else { return }
        
        // Move preview with finger
        let location = gesture.location(in: containerView)
        preview.center = location
        
        // Convert to canvas coordinates
        let canvasLocation = containerView.convert(location, to: canvasView)
        
        // Precise hit test: only highlight when directly over a slot's diamond shape
        if let hitSlot = canvasView.slotAt(canvasPoint: canvasLocation),
           !hitSlot.isOccupied {
            canvasView.highlightActiveSlot(hitSlot)
            currentSlot = hitSlot
        } else {
            canvasView.hideActiveSlotRevertingState()
            currentSlot = nil
        }
    }
    
    func handleDragEnded(gesture: UIPanGestureRecognizer) {
        guard let canvasView = canvasView else {
            cleanupDrag()
            return
        }
        
        // Let the highlighted slot revert to its normal state when dropped
        canvasView.hideActiveSlotRevertingState()
        
        // Check if we have a valid drop slot
        if let slot = currentSlot, let treeData = currentTreeData {
            showConfirmation(at: slot, for: treeData)
        } else {
            // No valid drop - animate preview back
            animateCancelDrag()
        }
    }
    
    // MARK: - Confirmation Flow
    
    /// Triggered by a direct tap on an empty grid slot
    func showConfirmationForTap(at slot: PlacementSlot, for treeData: ReadyTreeData) {
        currentSlot = slot
        currentTreeData = treeData
        
        // No drag preview to animate, so just show the confirmation
        // and add the temporary view
        guard let containerView = containerView,
              let canvasView = canvasView else { return }
              
        let slotPositionInCanvas = slot.position
        let slotPositionInContainer = canvasView.convert(slotPositionInCanvas, to: containerView)
        
        showConfirmationView(at: slot, slotPositionInContainer: slotPositionInContainer, for: treeData)
    }
    
    private func showConfirmation(at slot: PlacementSlot, for treeData: ReadyTreeData) {
        guard let containerView = containerView,
              let canvasView = canvasView,
              let preview = dragPreview else { return }
        
        // Calculate screen position for the slot
        let slotPositionInCanvas = slot.position
        let slotPositionInContainer = canvasView.convert(slotPositionInCanvas, to: containerView)
        
        // Animate preview to slot position
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            preview.center = slotPositionInContainer
            preview.transform = .identity
        }
        
        showConfirmationView(at: slot, slotPositionInContainer: slotPositionInContainer, for: treeData)
        
        // Hide the drag preview (we have the temp tree now)
        UIView.animate(withDuration: 0.2) {
            preview.alpha = 0
        }
    }
    
    private func showConfirmationView(at slot: PlacementSlot, slotPositionInContainer: CGPoint, for treeData: ReadyTreeData) {
        guard let containerView = containerView,
              let canvasView = canvasView else { return }
        
        
        // Create temporary tree on canvas (for visual feedback)
        if let image = treeData.treeType?.image(for: .adult) {
            let tempTree = UIImageView(image: image)
            tempTree.contentMode = .scaleAspectFit
            tempTree.frame = CGRect(
                x: slot.position.x - AppConstants.Garden.treeSize / 2,
                y: slot.position.y - AppConstants.Garden.treeSize + 15,
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
            confirmation.widthAnchor.constraint(equalToConstant: 140),
            confirmation.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        containerView.layoutIfNeeded()
        confirmation.show()
        confirmationView = confirmation
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
