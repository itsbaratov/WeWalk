//
//  GardenCanvasView.swift
//  WeWalkApp
//
//  Isometric garden canvas with calibrated ground geometry and slot interaction
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

struct GardenSlotSelection {
    enum Source {
        case directHit
        case magnetic
        case hysteresis
    }

    let slot: PlacementSlot
    let source: Source
}

private struct GardenDiamond {
    let top: CGPoint
    let right: CGPoint
    let bottom: CGPoint
    let left: CGPoint

    var center: CGPoint {
        CGPoint(x: (top.x + bottom.x) / 2, y: (top.y + bottom.y) / 2)
    }

    func inset(towardCenter factor: CGFloat) -> GardenDiamond {
        let center = center

        func lerp(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: point.x + (center.x - point.x) * factor,
                y: point.y + (center.y - point.y) * factor
            )
        }

        return GardenDiamond(
            top: lerp(top),
            right: lerp(right),
            bottom: lerp(bottom),
            left: lerp(left)
        )
    }

    func contains(_ point: CGPoint) -> Bool {
        let center = center
        let halfWidth = max(abs(right.x - center.x), abs(center.x - left.x))
        let halfHeight = max(abs(bottom.y - center.y), abs(center.y - top.y))
        guard halfWidth > 0, halfHeight > 0 else { return false }

        let normalizedX = abs(point.x - center.x) / halfWidth
        let normalizedY = abs(point.y - center.y) / halfHeight
        return (normalizedX + normalizedY) <= 1.0
    }
}

private extension CGPoint {
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }

    static func / (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        guard rhs != 0 else { return .zero }
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }

    func distance(to other: CGPoint) -> CGFloat {
        let dx = x - other.x
        let dy = y - other.y
        return sqrt(dx * dx + dy * dy)
    }
}

private struct GardenCanvasGeometry {
    let canvasBounds: CGRect
    let renderedGroundFrame: CGRect
    let surfaceDiamond: GardenDiamond
    let plantingDiamond: GardenDiamond
    let rowStep: CGPoint
    let colStep: CGPoint
    let logicalTileSize: CGSize
    let visualTileSize: CGSize
    let interactionTileSize: CGSize
    let treeSize: CGFloat
    let treeBaseYOffset: CGFloat
    let magneticSelectionRadius: CGFloat
    let hysteresisRadius: CGFloat

    private struct SelectionCandidate {
        let slot: PlacementSlot
        let distance: CGFloat
    }

    init?(canvasBounds: CGRect, groundImage: UIImage?) {
        guard !canvasBounds.isEmpty,
              let image = groundImage,
              image.size.width > 0,
              image.size.height > 0 else {
            return nil
        }

        self.canvasBounds = canvasBounds
        self.renderedGroundFrame = GardenCanvasGeometry.aspectFitRect(
            for: image.size,
            in: canvasBounds
        )

        let ground = renderedGroundFrame
        let top = GardenCanvasGeometry.denormalize(
            AppConstants.Garden.surfaceTopVertexNormalized,
            in: ground
        )
        let right = GardenCanvasGeometry.denormalize(
            AppConstants.Garden.surfaceRightVertexNormalized,
            in: ground
        )
        let bottom = GardenCanvasGeometry.denormalize(
            AppConstants.Garden.surfaceBottomVertexNormalized,
            in: ground
        )
        let left = GardenCanvasGeometry.denormalize(
            AppConstants.Garden.surfaceLeftVertexNormalized,
            in: ground
        )

        self.surfaceDiamond = GardenDiamond(
            top: top,
            right: right,
            bottom: bottom,
            left: left
        )
        self.plantingDiamond = surfaceDiamond.inset(
            towardCenter: AppConstants.Garden.cornerSafeInsetRatio
        )

        let rows = CGFloat(max(AppConstants.Garden.gridRows, 1))
        let cols = CGFloat(max(AppConstants.Garden.gridCols, 1))
        self.rowStep = (plantingDiamond.left - plantingDiamond.top) / rows
        self.colStep = (plantingDiamond.right - plantingDiamond.top) / cols

        let logicalWidth = abs(rowStep.x) + abs(colStep.x)
        let logicalHeight = abs(rowStep.y) + abs(colStep.y)
        self.logicalTileSize = CGSize(width: logicalWidth, height: logicalHeight)

        let visualScale = GardenCanvasGeometry.clamp(
            AppConstants.Garden.slotVisualScale,
            min: 0.4,
            max: 1.0
        )
        self.visualTileSize = CGSize(
            width: logicalWidth * visualScale,
            height: logicalHeight * visualScale
        )

        let interactionScale = GardenCanvasGeometry.clamp(
            AppConstants.Garden.slotInteractionScale,
            min: visualScale,
            max: 1.0
        )
        let expandedWidth = visualTileSize.width + AppConstants.Garden.interactionExpansionRadius * 2
        let expandedHeight = visualTileSize.height + AppConstants.Garden.interactionExpansionRadius * 2
        self.interactionTileSize = CGSize(
            width: min(logicalWidth * interactionScale, max(visualTileSize.width, expandedWidth)),
            height: min(logicalHeight * interactionScale, max(visualTileSize.height, expandedHeight))
        )

        let proposedTreeSize = logicalWidth * AppConstants.Garden.treeScaleRatio
        self.treeSize = GardenCanvasGeometry.clamp(
            proposedTreeSize,
            min: AppConstants.Garden.treeMinSize,
            max: AppConstants.Garden.treeMaxSize
        )
        self.treeBaseYOffset = treeSize * AppConstants.Garden.treeBaseAnchorRatio

        let maxTileDimension = max(logicalWidth, logicalHeight)
        self.magneticSelectionRadius = maxTileDimension * AppConstants.Garden.magneticSelectionRadiusRatio
            + AppConstants.Garden.interactionExpansionRadius
        self.hysteresisRadius = AppConstants.Garden.dragSelectionHysteresisRadius
    }

    func slotCenter(for slot: PlacementSlot) -> CGPoint {
        plantingDiamond.top
            + rowStep * (CGFloat(slot.row) + 0.5)
            + colStep * (CGFloat(slot.col) + 0.5)
    }

    func visualSlotFrame(for slot: PlacementSlot) -> CGRect {
        let center = slotCenter(for: slot)
        return CGRect(
            x: center.x - visualTileSize.width / 2,
            y: center.y - visualTileSize.height / 2,
            width: visualTileSize.width,
            height: visualTileSize.height
        )
    }

    func visualSlotPath(for slot: PlacementSlot) -> UIBezierPath {
        diamondPath(center: slotCenter(for: slot), size: visualTileSize)
    }

    func interactionSlotPath(for slot: PlacementSlot) -> UIBezierPath {
        diamondPath(center: slotCenter(for: slot), size: interactionTileSize)
    }

    func containsPlantablePoint(_ point: CGPoint) -> Bool {
        plantingDiamond.contains(point)
    }

    func resolveSelection(
        at point: CGPoint,
        slots: [PlacementSlot],
        preferredSlot: PlacementSlot?
    ) -> GardenSlotSelection? {
        guard containsPlantablePoint(point) else { return nil }

        // Never allow occupied cells to become active or redirect to nearby empties on a direct hit.
        for slot in slots where slot.isOccupied {
            if interactionSlotPath(for: slot).contains(point) {
                return nil
            }
        }

        var directCandidate: SelectionCandidate?
        var nearestCandidate: SelectionCandidate?

        for slot in slots where !slot.isOccupied {
            let center = slotCenter(for: slot)
            let distance = center.distance(to: point)

            if nearestCandidate == nil || distance < nearestCandidate!.distance {
                nearestCandidate = SelectionCandidate(slot: slot, distance: distance)
            }

            if interactionSlotPath(for: slot).contains(point),
               (directCandidate == nil || distance < directCandidate!.distance) {
                directCandidate = SelectionCandidate(slot: slot, distance: distance)
            }
        }

        guard var selected = directCandidate ?? nearestCandidate else { return nil }
        var source: GardenSlotSelection.Source = directCandidate == nil ? .magnetic : .directHit

        if directCandidate == nil, selected.distance > magneticSelectionRadius {
            return nil
        }

        if let preferredSlot,
           !preferredSlot.isOccupied,
           preferredSlot.id != selected.slot.id,
           slots.contains(where: { $0.id == preferredSlot.id && !$0.isOccupied }) {
            let preferredDistance = slotCenter(for: preferredSlot).distance(to: point)
            if interactionSlotPath(for: preferredSlot).contains(point)
                || preferredDistance <= (selected.distance + hysteresisRadius) {
                selected = SelectionCandidate(slot: preferredSlot, distance: preferredDistance)
                source = .hysteresis
            }
        }

        return GardenSlotSelection(slot: selected.slot, source: source)
    }

    func treeFrame(for slot: PlacementSlot) -> CGRect {
        let center = slotCenter(for: slot)
        return CGRect(
            x: center.x - treeSize / 2,
            y: center.y - treeBaseYOffset,
            width: treeSize,
            height: treeSize
        )
    }

    func treeBaseAnchor(for slot: PlacementSlot) -> CGPoint {
        slotCenter(for: slot)
    }

    private func diamondPath(center: CGPoint, size: CGSize) -> UIBezierPath {
        let halfWidth = size.width / 2
        let halfHeight = size.height / 2

        let top = CGPoint(x: center.x, y: center.y - halfHeight)
        let right = CGPoint(x: center.x + halfWidth, y: center.y)
        let bottom = CGPoint(x: center.x, y: center.y + halfHeight)
        let left = CGPoint(x: center.x - halfWidth, y: center.y)

        let path = UIBezierPath()
        path.move(to: top)
        path.addLine(to: right)
        path.addLine(to: bottom)
        path.addLine(to: left)
        path.close()
        return path
    }

    private static func denormalize(_ point: CGPoint, in rect: CGRect) -> CGPoint {
        CGPoint(
            x: rect.minX + rect.width * point.x,
            y: rect.minY + rect.height * point.y
        )
    }

    private static func aspectFitRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
        let scale = min(bounds.width / imageSize.width, bounds.height / imageSize.height)
        let size = CGSize(width: imageSize.width * scale, height: imageSize.height * scale)
        return CGRect(
            x: bounds.midX - size.width / 2,
            y: bounds.midY - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    private static func clamp(_ value: CGFloat, min minValue: CGFloat, max maxValue: CGFloat) -> CGFloat {
        Swift.max(minValue, Swift.min(value, maxValue))
    }
}

final class IsometricSlotView: UIView {

    override class var layerClass: AnyClass {
        CAShapeLayer.self
    }

    var shapeLayer: CAShapeLayer {
        layer as! CAShapeLayer
    }

    private(set) var diamondPath: CGPath?

    private let dashedBorderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.white.withAlphaComponent(0.4).cgColor
        layer.lineDashPattern = [6, 4]
        layer.lineWidth = 1.5
        layer.lineJoin = .round
        layer.lineCap = .round
        return layer
    }()

    private let glowLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.clear.cgColor
        layer.lineWidth = 0
        layer.lineJoin = .round
        layer.lineCap = .round
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
        updatePath()
    }

    private func updatePath() {
        let insetBounds = bounds.insetBy(dx: 0.5, dy: 0.5)
        let top = CGPoint(x: insetBounds.midX, y: insetBounds.minY)
        let right = CGPoint(x: insetBounds.maxX, y: insetBounds.midY)
        let bottom = CGPoint(x: insetBounds.midX, y: insetBounds.maxY)
        let left = CGPoint(x: insetBounds.minX, y: insetBounds.midY)

        let path = UIBezierPath()
        path.move(to: top)
        path.addLine(to: right)
        path.addLine(to: bottom)
        path.addLine(to: left)
        path.close()

        shapeLayer.path = path.cgPath
        dashedBorderLayer.path = path.cgPath
        glowLayer.path = path.cgPath
        dashedBorderLayer.frame = bounds
        glowLayer.frame = bounds
        diamondPath = path.cgPath
    }

    func setState(_ state: SlotState) {
        layer.removeAllAnimations()
        transform = .identity

        switch state {
        case .empty:
            shapeLayer.fillColor = UIColor.white.withAlphaComponent(0.10).cgColor
            shapeLayer.strokeColor = UIColor.clear.cgColor
            shapeLayer.lineWidth = 0
            dashedBorderLayer.strokeColor = UIColor.white.withAlphaComponent(0.42).cgColor
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
            shapeLayer.lineWidth = 2.2
            dashedBorderLayer.isHidden = true

            glowLayer.isHidden = false
            glowLayer.strokeColor = UIColor.appMintGreen.withAlphaComponent(0.25).cgColor
            glowLayer.lineWidth = 5

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

    func containsPoint(_ point: CGPoint) -> Bool {
        guard let path = diamondPath else { return false }
        return path.contains(point)
    }
}

final class GardenCanvasView: UIView {

    weak var delegate: GardenCanvasViewDelegate?

    private var treeViews: [UUID: UIImageView] = [:]
    private var treeSlots: [UUID: PlacementSlot] = [:]
    private var slotViews: [UUID: IsometricSlotView] = [:]
    private var slotData: [UUID: PlacementSlot] = [:]
    private var highlightedSlot: PlacementSlot?
    private var hasTapGesture = false
    private var currentGrid: GardenGrid?
    private var geometry: GardenCanvasGeometry?

    private let groundImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "new_ground")
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()

    private let plantingIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.appMintGreen.withAlphaComponent(0.34)
        view.layer.borderColor = UIColor.appMintGreen.withAlphaComponent(0.85).cgColor
        view.layer.borderWidth = 1.5
        view.layer.cornerRadius = 12
        view.isHidden = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }

    private func setupView() {
        backgroundColor = .clear

        addSubview(groundImageView)
        addSubview(plantingIndicatorView)

        NSLayoutConstraint.activate([
            groundImageView.topAnchor.constraint(equalTo: topAnchor),
            groundImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            groundImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            groundImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    override var intrinsicContentSize: CGSize {
        CGSize(width: AppConstants.Garden.canvasSize, height: AppConstants.Garden.canvasSize)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        relayoutCanvas()
    }

    func setupGridStyles(grid: GardenGrid) {
        currentGrid = grid
        syncSlotViews(with: grid)

        if !hasTapGesture {
            let tap = UITapGestureRecognizer(target: self, action: #selector(handleCanvasTap(_:)))
            addGestureRecognizer(tap)
            isUserInteractionEnabled = true
            hasTapGesture = true
        }

        setNeedsLayout()
    }

    @objc private func handleCanvasTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        guard let selection = resolveSlotSelection(at: location, preferredSlot: nil) else { return }
        highlightActiveSlot(selection.slot)
        delegate?.gardenCanvas(self, didSelectSlot: selection.slot)
    }

    func addTree(image: UIImage, at slot: PlacementSlot, treeId: UUID, animated: Bool = true) {
        let treeView = UIImageView(image: image)
        treeView.contentMode = .scaleAspectFit
        treeView.frame = treeFrame(for: slot)
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
        treeSlots[treeId] = slot

        if let slotView = slotViews[slot.id] {
            slotView.setState(.occupied)
        }

        sortTreesByDepth()

        if animated {
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8) {
                treeView.transform = .identity
                treeView.alpha = 1
            }

            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
    }

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
        treeSlots.removeValue(forKey: id)
    }

    func clearTrees() {
        treeViews.values.forEach { $0.removeFromSuperview() }
        treeViews.removeAll()
        treeSlots.removeAll()
    }

    func highlightActiveSlot(_ slot: PlacementSlot?) {
        guard slot?.id != highlightedSlot?.id else { return }

        if let previousSlot = highlightedSlot,
           let latestPreviousSlot = slotData[previousSlot.id],
           let previousView = slotViews[previousSlot.id] {
            previousView.setState(latestPreviousSlot.isOccupied ? .occupied : .empty)
        }

        highlightedSlot = slot

        if let slot,
           let latestSlot = slotData[slot.id],
           !latestSlot.isOccupied,
           let slotView = slotViews[slot.id] {
            highlightedSlot = latestSlot
            slotView.setState(.active)
            showPlantingIndicator(for: latestSlot)
            bringSubviewToFront(slotView)

            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        } else {
            highlightedSlot = nil
            hidePlantingIndicator()
        }
    }

    func hideActiveSlotRevertingState() {
        if let currentSlot = highlightedSlot,
           let latestSlot = slotData[currentSlot.id],
           let currentView = slotViews[currentSlot.id] {
            currentView.setState(latestSlot.isOccupied ? .occupied : .empty)
        }
        highlightedSlot = nil
        hidePlantingIndicator()
        sortTreesByDepth()
    }

    func getHighlightedSlot() -> PlacementSlot? {
        highlightedSlot
    }

    func canvasPoint(from point: CGPoint, in view: UIView) -> CGPoint {
        convert(point, from: view)
    }

    func resolveSlotSelection(at canvasPoint: CGPoint, preferredSlot: PlacementSlot?) -> GardenSlotSelection? {
        guard let geometry else { return nil }
        return geometry.resolveSelection(
            at: canvasPoint,
            slots: Array(slotData.values),
            preferredSlot: preferredSlot
        )
    }

    func slotAt(canvasPoint point: CGPoint) -> PlacementSlot? {
        resolveSlotSelection(at: point, preferredSlot: nil)?.slot
    }

    func isWithinGrassArea(_ point: CGPoint) -> Bool {
        geometry?.containsPlantablePoint(point) == true
    }

    func treeFrame(for slot: PlacementSlot) -> CGRect {
        geometry?.treeFrame(for: slot) ?? .zero
    }

    func treeBaseAnchor(for slot: PlacementSlot) -> CGPoint {
        geometry?.treeBaseAnchor(for: slot) ?? .zero
    }

    private func syncSlotViews(with grid: GardenGrid) {
        let slots = grid.slots.flatMap { $0 }
        let ids = Set(slots.map(\.id))
        let idsToRemove = slotViews.keys.filter { !ids.contains($0) }

        for id in idsToRemove {
            slotViews[id]?.removeFromSuperview()
            slotViews.removeValue(forKey: id)
            slotData.removeValue(forKey: id)
        }

        for slot in slots {
            let slotView = slotViews[slot.id] ?? IsometricSlotView()
            if slotViews[slot.id] == nil {
                addSubview(slotView)
                slotViews[slot.id] = slotView
            }
            slotData[slot.id] = slot
            slotView.setState(slot.isOccupied ? .occupied : .empty)
        }
    }

    private func relayoutCanvas() {
        geometry = GardenCanvasGeometry(
            canvasBounds: bounds,
            groundImage: groundImageView.image
        )

        guard let currentGrid, let geometry else { return }

        for slot in currentGrid.slots.flatMap({ $0 }) {
            guard let slotView = slotViews[slot.id] else { continue }
            slotData[slot.id] = slot
            slotView.frame = geometry.visualSlotFrame(for: slot)
            slotView.setNeedsLayout()
            slotView.setState(slot.isOccupied ? .occupied : .empty)
        }

        for (treeId, treeView) in treeViews {
            guard let slot = treeSlots[treeId] else { continue }
            treeView.frame = geometry.treeFrame(for: slot)
        }

        if let highlightedSlot,
           let latestHighlighted = slotData[highlightedSlot.id],
           !latestHighlighted.isOccupied,
           let highlightedView = slotViews[highlightedSlot.id] {
            self.highlightedSlot = latestHighlighted
            highlightedView.setState(.active)
            showPlantingIndicator(for: latestHighlighted)
        } else {
            highlightedSlot = nil
            hidePlantingIndicator()
        }

        sortTreesByDepth()
    }

    private func showPlantingIndicator(for slot: PlacementSlot) {
        guard let geometry else { return }

        let anchor = geometry.treeBaseAnchor(for: slot)
        let indicatorSize = CGSize(
            width: geometry.logicalTileSize.width * 0.22,
            height: geometry.logicalTileSize.height * 0.18
        )
        plantingIndicatorView.bounds = CGRect(origin: .zero, size: indicatorSize)
        plantingIndicatorView.center = anchor
        plantingIndicatorView.layer.cornerRadius = indicatorSize.height / 2
        plantingIndicatorView.isHidden = false
        bringSubviewToFront(plantingIndicatorView)
    }

    private func hidePlantingIndicator() {
        plantingIndicatorView.isHidden = true
    }

    private func sortTreesByDepth() {
        sendSubviewToBack(groundImageView)

        for slotView in slotViews.values {
            bringSubviewToFront(slotView)
        }

        let sortedTrees = treeViews.values.sorted { $0.frame.origin.y < $1.frame.origin.y }
        for tree in sortedTrees {
            bringSubviewToFront(tree)
        }

        if let activeSlot = highlightedSlot, let activeView = slotViews[activeSlot.id] {
            bringSubviewToFront(activeView)
        }

        if !plantingIndicatorView.isHidden {
            bringSubviewToFront(plantingIndicatorView)
        }
    }
}
