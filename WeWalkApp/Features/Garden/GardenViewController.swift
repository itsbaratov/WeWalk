//
//  GardenViewController.swift
//  WeWalkApp
//
//  Virtual garden screen with drag-and-drop tree planting
//

import UIKit
import Combine

final class GardenViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var coordinator: GardenCoordinator?
    private let viewModel: GardenViewModel
    private var cancellables = Set<AnyCancellable>()
    private var plantingCoordinator: TreePlantingCoordinator?
    
    // MARK: - UI Elements
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .appPrimaryGreen
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Garden"
        label.font = .appTitleLarge
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let addButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let subtitleContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .appPrimaryGreen
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let gardenTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Virtual garden"
        label.font = .appTitleSmall
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let gardenSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Fully grown trees planted from past goals."
        label.font = .appCaption
        label.textColor = .appSecondaryTextOnDark
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .appCaption
        label.textColor = .appSecondaryTextOnDark
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let gardenContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .appPrimaryGreen
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    

    
    private let gardenView: GardenCanvasView = {
        let view = GardenCanvasView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let archiveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Canopy Archives", for: .normal)
        button.backgroundColor = .appMintGreen
        button.setTitleColor(.appPrimaryGreen, for: .normal)
        button.titleLabel?.font = .appLabelBold
        button.layer.cornerRadius = 20
        button.isHidden = true  // Hidden by default
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let readyToPlantView: UIView = {
        let view = UIView()
        view.backgroundColor = .appCardBackground
        view.layer.cornerRadius = 20
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: -4)
        view.layer.shadowRadius = 12
        view.layer.shadowOpacity = 0.12
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let readyLabel: UILabel = {
        let label = UILabel()
        label.text = "Ready to Plant"
        label.font = .appTitleSmall
        label.textColor = .appTextOnLight
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let readyTreesScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let readyTreesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let emptyStateLabel: UILabel = {
        let label = UILabel()
        label.text = "Complete your daily goal to grow a tree!"
        label.font = .appCaption
        label.textColor = .secondaryLabel
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Init
    
    init(viewModel: GardenViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupActions()
        setupPlantingCoordinator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.checkForReadyTrees()
    }
    


    
    // MARK: - Layout
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scaleGardenCanvas()
    }
    
    private func scaleGardenCanvas() {
        guard gardenContainerView.bounds.width > 0 else { return }
        
        // Calculate scale to fit the 1024 canvas into the container width
        let containerWidth = gardenContainerView.bounds.width
        let scale = containerWidth / AppConstants.Garden.canvasSize
        
        // Apply scale transform
        gardenView.transform = CGAffineTransform(scaleX: scale, y: scale)
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .appPrimaryGreen
        
        // Header
        view.addSubview(headerView)
        headerView.addSubview(backButton)
        headerView.addSubview(titleLabel)
        headerView.addSubview(addButton)
        
        // Subtitle area
        view.addSubview(subtitleContainer)
        subtitleContainer.addSubview(gardenTitleLabel)
        subtitleContainer.addSubview(gardenSubtitleLabel)
        subtitleContainer.addSubview(countLabel)
        
        // Garden canvas
        view.addSubview(gardenContainerView)
        gardenContainerView.addSubview(gardenView)
        
        // Archive button
        view.addSubview(archiveButton)
        
        // Add delegate
        gardenView.delegate = self
        
        // Ready to plant tray
        view.addSubview(readyToPlantView)
        readyToPlantView.addSubview(readyLabel)
        readyToPlantView.addSubview(readyTreesScrollView)
        readyTreesScrollView.addSubview(readyTreesStack)
        readyToPlantView.addSubview(emptyStateLabel)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        let canvasSize = AppConstants.Garden.canvasSize
        
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            backButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 16),
            backButton.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            
            addButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 44),
            addButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Subtitle
            subtitleContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            subtitleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            subtitleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            subtitleContainer.heightAnchor.constraint(equalToConstant: 60),
            
            gardenTitleLabel.topAnchor.constraint(equalTo: subtitleContainer.topAnchor, constant: 8),
            gardenTitleLabel.leadingAnchor.constraint(equalTo: subtitleContainer.leadingAnchor, constant: 16),
            
            gardenSubtitleLabel.topAnchor.constraint(equalTo: gardenTitleLabel.bottomAnchor, constant: 4),
            gardenSubtitleLabel.leadingAnchor.constraint(equalTo: subtitleContainer.leadingAnchor, constant: 16),
            
            countLabel.centerYAnchor.constraint(equalTo: subtitleContainer.centerYAnchor),
            countLabel.trailingAnchor.constraint(equalTo: subtitleContainer.trailingAnchor, constant: -16),
            
            // Garden container (fills available space with padding)
            gardenContainerView.topAnchor.constraint(equalTo: subtitleContainer.bottomAnchor),
            gardenContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            gardenContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            gardenContainerView.bottomAnchor.constraint(equalTo: readyToPlantView.topAnchor),
            
            // Garden Canvas (centered and fixed size, scaled down in layout)
            gardenView.centerXAnchor.constraint(equalTo: gardenContainerView.centerXAnchor),
            gardenView.centerYAnchor.constraint(equalTo: gardenContainerView.centerYAnchor),
            gardenView.widthAnchor.constraint(equalToConstant: canvasSize),
            gardenView.heightAnchor.constraint(equalToConstant: canvasSize),
            
            // Archive button
            archiveButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            archiveButton.bottomAnchor.constraint(equalTo: readyToPlantView.topAnchor, constant: -16),
            archiveButton.widthAnchor.constraint(equalToConstant: 180),
            archiveButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Ready to plant
            readyToPlantView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            readyToPlantView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            readyToPlantView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            readyToPlantView.heightAnchor.constraint(equalToConstant: 130),
            
            readyLabel.topAnchor.constraint(equalTo: readyToPlantView.topAnchor, constant: 16),
            readyLabel.leadingAnchor.constraint(equalTo: readyToPlantView.leadingAnchor, constant: 16),
            
            readyTreesScrollView.topAnchor.constraint(equalTo: readyLabel.bottomAnchor, constant: 12),
            readyTreesScrollView.leadingAnchor.constraint(equalTo: readyToPlantView.leadingAnchor, constant: 16),
            readyTreesScrollView.trailingAnchor.constraint(equalTo: readyToPlantView.trailingAnchor, constant: -16),
            readyTreesScrollView.bottomAnchor.constraint(equalTo: readyToPlantView.bottomAnchor, constant: -16),
            
            readyTreesStack.topAnchor.constraint(equalTo: readyTreesScrollView.topAnchor),
            readyTreesStack.leadingAnchor.constraint(equalTo: readyTreesScrollView.leadingAnchor),
            readyTreesStack.trailingAnchor.constraint(equalTo: readyTreesScrollView.trailingAnchor),
            readyTreesStack.bottomAnchor.constraint(equalTo: readyTreesScrollView.bottomAnchor),
            readyTreesStack.heightAnchor.constraint(equalTo: readyTreesScrollView.heightAnchor),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: readyTreesScrollView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: readyTreesScrollView.centerYAnchor)
        ])
    }
    
    private func setupBindings() {
        viewModel.$currentGardenTreeCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.countLabel.text = "\(count)/\(AppConstants.Garden.maxCapacity)"
            }
            .store(in: &cancellables)
        
        viewModel.$plantedTrees
            .receive(on: DispatchQueue.main)
            .sink { [weak self] trees in
                self?.updateGardenCanvas(with: trees)
            }
            .store(in: &cancellables)
        
        viewModel.$readyToPlantTrees
            .receive(on: DispatchQueue.main)
            .sink { [weak self] trees in
                self?.updateReadyTreesStack(with: trees)
            }
            .store(in: &cancellables)
        
        viewModel.$hasArchivedGardens
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hasArchives in
                self?.archiveButton.isHidden = !hasArchives
            }
            .store(in: &cancellables)
        
        viewModel.$gardenGrid
            .receive(on: DispatchQueue.main)
            .sink { [weak self] grid in
                self?.gardenView.setupGridStyles(grid: grid)
                self?.plantingCoordinator?.updateGrid(grid)
            }
            .store(in: &cancellables)
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        archiveButton.addTarget(self, action: #selector(showArchived), for: .touchUpInside)
    }
    
    private func setupPlantingCoordinator() {
        plantingCoordinator = TreePlantingCoordinator(
            containerView: view,
            canvasView: gardenView,
            grid: viewModel.getGrid()
        )
        plantingCoordinator?.delegate = self
    }
    
    // MARK: - UI Updates
    
    private func updateGardenCanvas(with trees: [PlantedTreeData]) {
        gardenView.clearTrees()
        for tree in trees {
            if let slot = viewModel.getGrid().slot(at: tree.row, col: tree.col),
               let image = viewModel.getTreeImage(for: tree.treeTypeId) {
                gardenView.addTree(image: image, at: slot, treeId: tree.id, animated: false)
            }
        }
    }
    
    private func updateReadyTreesStack(with trees: [ReadyTreeData]) {
        readyTreesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        emptyStateLabel.isHidden = !trees.isEmpty
        
        for tree in trees {
            let treeCard = DraggableTreeCardView()
            treeCard.configure(with: tree)
            treeCard.delegate = self
            treeCard.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                treeCard.widthAnchor.constraint(equalToConstant: 60),
                treeCard.heightAnchor.constraint(equalToConstant: 60)
            ])
            
            readyTreesStack.addArrangedSubview(treeCard)
        }
    }
    
    // MARK: - Actions
    
    @objc private func backTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func showArchived() {
        coordinator?.showArchivedGardens()
    }
}



// MARK: - DraggableTreeCardDelegate

extension GardenViewController: DraggableTreeCardDelegate {
    func treeCard(_ card: DraggableTreeCardView, didBeginDragWith gesture: UIPanGestureRecognizer) {
        plantingCoordinator?.handleDragBegan(from: card, gesture: gesture)
    }
    
    func treeCard(_ card: DraggableTreeCardView, didMoveDragWith gesture: UIPanGestureRecognizer) {
        plantingCoordinator?.handleDragMoved(gesture: gesture)
    }
    
    func treeCard(_ card: DraggableTreeCardView, didEndDragWith gesture: UIPanGestureRecognizer) {
        plantingCoordinator?.handleDragEnded(gesture: gesture)
    }
}

// MARK: - TreePlantingCoordinatorDelegate

extension GardenViewController: TreePlantingCoordinatorDelegate {
    func coordinatorDidConfirmPlanting(at slot: PlacementSlot, treeData: ReadyTreeData) {
        // Add tree to the garden
        viewModel.plantTree(at: slot, treeData: treeData)
        
        // Add tree to canvas with animation
        if let image = viewModel.getTreeImage(for: treeData.treeTypeId) {
            gardenView.addTree(image: image, at: slot, treeId: UUID(), animated: true)
        }
    }
    
    func coordinatorDidCancelPlanting() {
        // Tree returns to tray, nothing to do
    }
}

// MARK: - GardenCanvasViewDelegate

extension GardenViewController: GardenCanvasViewDelegate {
    func gardenCanvas(_ canvas: GardenCanvasView, didSelectSlot slot: PlacementSlot) {
        // Tap-to-plant: Get the first available tree
        guard let firstTree = viewModel.readyToPlantTrees.first else { return }
        
        // Bypass the drag coordinator and show confirmation directly
        plantingCoordinator?.showConfirmationForTap(at: slot, for: firstTree)
    }
}
