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

    weak var delegate: TreePlantingCoordinatorDelegate?

    private weak var containerView: UIView?
    private weak var canvasView: GardenCanvasView?

    private var dragPreview: UIImageView?
    private var dragPreviewBaseAnchor: CGPoint = .zero
    private var currentTreeData: ReadyTreeData?
    private var currentSlot: PlacementSlot?

    private var confirmationView: InlinePlantConfirmationView?
    private var temporaryTreeView: UIImageView?

    private var gardenGrid: GardenGrid

    init(containerView: UIView, canvasView: GardenCanvasView, grid: GardenGrid) {
        self.containerView = containerView
        self.canvasView = canvasView
        self.gardenGrid = grid
        super.init()
    }

    func updateGrid(_ grid: GardenGrid) {
        gardenGrid = grid
    }

    func handleDragBegan(from card: DraggableTreeCardView, gesture: UIPanGestureRecognizer) {
        guard let containerView = containerView,
              let treeData = card.treeData,
              let descriptor = card.makeDragPreviewDescriptor() else { return }

        currentTreeData = treeData
        currentSlot = nil
        dragPreviewBaseAnchor = descriptor.baseAnchor

        let preview = card.createDragPreview()
        let location = gesture.location(in: containerView)
        preview.frame.origin = previewOrigin(forFingerLocation: location, previewSize: descriptor.size)
        containerView.addSubview(preview)
        dragPreview = preview

        preview.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
            preview.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
        }
    }

    func handleDragMoved(gesture: UIPanGestureRecognizer) {
        guard let containerView = containerView,
              let preview = dragPreview,
              let canvasView = canvasView else { return }

        let location = gesture.location(in: containerView)
        preview.frame.origin = previewOrigin(forFingerLocation: location, previewSize: preview.bounds.size)

        let previewBaseInContainer = CGPoint(
            x: preview.frame.minX + dragPreviewBaseAnchor.x,
            y: preview.frame.minY + dragPreviewBaseAnchor.y
        )
        let canvasLocation = containerView.convert(previewBaseInContainer, to: canvasView)

        if let selection = canvasView.resolveSlotSelection(at: canvasLocation, preferredSlot: currentSlot) {
            canvasView.highlightActiveSlot(selection.slot)
            currentSlot = selection.slot
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

        if let slot = currentSlot, let treeData = currentTreeData {
            showConfirmation(at: slot, for: treeData)
        } else {
            canvasView.hideActiveSlotRevertingState()
            animateCancelDrag()
        }
    }

    func showConfirmationForTap(at slot: PlacementSlot, for treeData: ReadyTreeData) {
        currentSlot = slot
        currentTreeData = treeData

        guard let containerView = containerView,
              let canvasView = canvasView else { return }

        canvasView.highlightActiveSlot(slot)
        let slotAnchorInCanvas = canvasView.treeBaseAnchor(for: slot)
        let slotAnchorInContainer = canvasView.convert(slotAnchorInCanvas, to: containerView)
        showConfirmationView(at: slot, slotPositionInContainer: slotAnchorInContainer, for: treeData)
    }

    private func showConfirmation(at slot: PlacementSlot, for treeData: ReadyTreeData) {
        guard let containerView = containerView,
              let canvasView = canvasView,
              let preview = dragPreview else { return }

        let slotAnchorInCanvas = canvasView.treeBaseAnchor(for: slot)
        let slotAnchorInContainer = canvasView.convert(slotAnchorInCanvas, to: containerView)

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            preview.frame.origin = CGPoint(
                x: slotAnchorInContainer.x - self.dragPreviewBaseAnchor.x,
                y: slotAnchorInContainer.y - self.dragPreviewBaseAnchor.y
            )
            preview.transform = .identity
        }

        showConfirmationView(at: slot, slotPositionInContainer: slotAnchorInContainer, for: treeData)

        UIView.animate(withDuration: 0.2) {
            preview.alpha = 0
        }
    }

    private func showConfirmationView(at slot: PlacementSlot, slotPositionInContainer: CGPoint, for treeData: ReadyTreeData) {
        guard let containerView = containerView,
              let canvasView = canvasView else { return }

        if let image = treeData.treeType?.image(for: .adult) {
            let tempTree = UIImageView(image: image)
            tempTree.contentMode = .scaleAspectFit
            tempTree.frame = canvasView.treeFrame(for: slot)
            tempTree.alpha = 0.7
            canvasView.addSubview(tempTree)
            temporaryTreeView = tempTree
        }

        let confirmation = InlinePlantConfirmationView()
        confirmation.delegate = self
        confirmation.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(confirmation)

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
        dragPreviewBaseAnchor = .zero
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

    private func previewOrigin(forFingerLocation location: CGPoint, previewSize: CGSize) -> CGPoint {
        CGPoint(
            x: location.x - previewSize.width / 2,
            y: location.y - AppConstants.Garden.dragFingerLift
        )
    }
}

extension TreePlantingCoordinator: InlinePlantConfirmationDelegate {

    func confirmationViewDidConfirm(_ view: InlinePlantConfirmationView) {
        guard let slot = currentSlot, let treeData = currentTreeData else {
            hideConfirmation()
            cleanupDrag()
            return
        }

        canvasView?.hideActiveSlotRevertingState()
        temporaryTreeView?.removeFromSuperview()
        temporaryTreeView = nil

        hideConfirmation()
        cleanupDrag()

        delegate?.coordinatorDidConfirmPlanting(at: slot, treeData: treeData)
    }

    func confirmationViewDidCancel(_ view: InlinePlantConfirmationView) {
        canvasView?.hideActiveSlotRevertingState()
        hideConfirmation()
        cleanupDrag()
        delegate?.coordinatorDidCancelPlanting()
    }
}
