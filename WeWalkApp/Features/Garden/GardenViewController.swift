//
//  GardenViewController.swift
//  WeWalkApp
//
//  Virtual garden screen with tree placement
//

import UIKit
import Combine

final class GardenViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var coordinator: GardenCoordinator?
    private let viewModel: GardenViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Elements
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .appPrimaryGreen
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
    
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .appCaption
        label.textColor = .appSecondaryTextOnDark
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
    
    private let gardenScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.minimumZoomScale = AppConstants.Garden.minZoomScale
        sv.maximumZoomScale = AppConstants.Garden.maxZoomScale
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let gardenView: GardenCanvasView = {
        let view = GardenCanvasView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let archivedButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Archived Gardens", for: .normal)
        button.backgroundColor = .appMintGreen
        button.setTitleColor(.appPrimaryGreen, for: .normal)
        button.titleLabel?.font = .appLabelBold
        button.layer.cornerRadius = 20
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let readyToPlantView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
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
    
    private let readyTreesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        viewModel.checkForReadyTrees()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .appPrimaryGreen
        
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(countLabel)
        headerView.addSubview(addButton)
        
        view.addSubview(gardenScrollView)
        gardenScrollView.addSubview(gardenView)
        gardenScrollView.delegate = self
        
        view.addSubview(archivedButton)
        view.addSubview(readyToPlantView)
        readyToPlantView.addSubview(readyLabel)
        readyToPlantView.addSubview(readyTreesStack)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            // Header
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 100),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.bottomAnchor.constraint(equalTo: headerView.bottomAnchor, constant: -16),
            
            countLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            countLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            
            addButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -16),
            addButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            addButton.widthAnchor.constraint(equalToConstant: 44),
            addButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Garden scroll
            gardenScrollView.topAnchor.constraint(equalTo: headerView.bottomAnchor),
            gardenScrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            gardenScrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            gardenScrollView.bottomAnchor.constraint(equalTo: readyToPlantView.topAnchor),
            
            gardenView.widthAnchor.constraint(equalToConstant: AppConstants.Garden.canvasWidth),
            gardenView.heightAnchor.constraint(equalToConstant: AppConstants.Garden.canvasHeight),
            gardenView.centerXAnchor.constraint(equalTo: gardenScrollView.centerXAnchor),
            gardenView.centerYAnchor.constraint(equalTo: gardenScrollView.centerYAnchor),
            
            // Archived button
            archivedButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            archivedButton.bottomAnchor.constraint(equalTo: readyToPlantView.topAnchor, constant: -16),
            archivedButton.widthAnchor.constraint(equalToConstant: 180),
            archivedButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Ready to plant
            readyToPlantView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            readyToPlantView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            readyToPlantView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            readyToPlantView.heightAnchor.constraint(equalToConstant: 120),
            
            readyLabel.topAnchor.constraint(equalTo: readyToPlantView.topAnchor, constant: 16),
            readyLabel.leadingAnchor.constraint(equalTo: readyToPlantView.leadingAnchor, constant: 16),
            
            readyTreesStack.topAnchor.constraint(equalTo: readyLabel.bottomAnchor, constant: 12),
            readyTreesStack.leadingAnchor.constraint(equalTo: readyToPlantView.leadingAnchor, constant: 16),
            readyTreesStack.trailingAnchor.constraint(lessThanOrEqualTo: readyToPlantView.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupBindings() {
        viewModel.$currentGardenTreeCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] count in
                self?.countLabel.text = "\(count)/\(AppConstants.Garden.maxCapacity) trees"
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
    }
    
    private func setupActions() {
        archivedButton.addTarget(self, action: #selector(showArchived), for: .touchUpInside)
    }
    
    // MARK: - UI Updates
    
    private func updateGardenCanvas(with trees: [PlantedTreeData]) {
        gardenView.clearTrees()
        for tree in trees {
            if let image = viewModel.getTreeImage(for: tree.treeTypeId) {
                gardenView.addTree(image: image, at: tree.position)
            }
        }
    }
    
    private func updateReadyTreesStack(with trees: [ReadyTreeData]) {
        readyTreesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for tree in trees {
            let treeView = createReadyTreeView(tree: tree)
            readyTreesStack.addArrangedSubview(treeView)
        }
        
        if trees.isEmpty {
            let emptyLabel = UILabel()
            emptyLabel.text = "Complete your daily goal to grow a tree!"
            emptyLabel.font = .appCaption
            emptyLabel.textColor = .secondaryLabel
            readyTreesStack.addArrangedSubview(emptyLabel)
        }
    }
    
    private func createReadyTreeView(tree: ReadyTreeData) -> UIView {
        let container = UIView()
        container.backgroundColor = .systemGray6
        container.layer.cornerRadius = 12
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let imageView = UIImageView()
        imageView.image = tree.treeType?.image(for: .adult)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            container.widthAnchor.constraint(equalToConstant: 60),
            container.heightAnchor.constraint(equalToConstant: 60),
            imageView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            imageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 50),
            imageView.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        return container
    }
    
    // MARK: - Actions
    
    @objc private func showArchived() {
        coordinator?.showArchivedGardens()
    }
}

// MARK: - UIScrollViewDelegate

extension GardenViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return gardenView
    }
}
