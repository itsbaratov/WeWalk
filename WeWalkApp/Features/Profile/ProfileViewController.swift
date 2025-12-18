//
//  ProfileViewController.swift
//  WeWalkApp
//
//  Profile screen with settings and achievements
//

import UIKit
import Combine

final class ProfileViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var coordinator: ProfileCoordinator?
    private let viewModel: ProfileViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Elements
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 24
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "person.circle"), for: .normal)
        button.tintColor = .appPrimaryGreen
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // Beautiful Trees Section
    private let treesSection: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let treesSectionTitle: UILabel = {
        let label = UILabel()
        label.text = "Beautiful trees"
        label.font = .appTitleLarge
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let treesSubtitle: UILabel = {
        let label = UILabel()
        label.text = "Real-world trees planted via API"
        label.font = .appCaption
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let treesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 160, height: 100)
        layout.minimumInteritemSpacing = 12
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    // Archived Gardens Section
    private let gardensSection: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray6
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let gardensSectionTitle: UILabel = {
        let label = UILabel()
        label.text = "My Archived Gardens"
        label.font = .appTitleMedium
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let gardensSubtitle: UILabel = {
        let label = UILabel()
        label.text = "Previous full gardens with original status"
        label.font = .appCaption
        label.textColor = .secondaryLabel
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let gardensStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Init
    
    init(viewModel: ProfileViewModel) {
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
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Profile"
        view.backgroundColor = .appPageBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "gearshape"),
            style: .plain,
            target: self,
            action: #selector(showSettings)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        // Trees section
        treesSection.addSubview(treesSectionTitle)
        treesSection.addSubview(treesSubtitle)
        treesSection.addSubview(treesCollectionView)
        contentStack.addArrangedSubview(treesSection)
        
        // Gardens section
        gardensSection.addSubview(gardensSectionTitle)
        gardensSection.addSubview(gardensSubtitle)
        gardensSection.addSubview(gardensStack)
        contentStack.addArrangedSubview(gardensSection)
        
        setupConstraints()
        setupCollectionView()
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            
            // Trees section
            treesSectionTitle.topAnchor.constraint(equalTo: treesSection.topAnchor),
            treesSectionTitle.leadingAnchor.constraint(equalTo: treesSection.leadingAnchor),
            
            treesSubtitle.topAnchor.constraint(equalTo: treesSectionTitle.bottomAnchor, constant: 4),
            treesSubtitle.leadingAnchor.constraint(equalTo: treesSection.leadingAnchor),
            
            treesCollectionView.topAnchor.constraint(equalTo: treesSubtitle.bottomAnchor, constant: 12),
            treesCollectionView.leadingAnchor.constraint(equalTo: treesSection.leadingAnchor),
            treesCollectionView.trailingAnchor.constraint(equalTo: treesSection.trailingAnchor),
            treesCollectionView.heightAnchor.constraint(equalToConstant: 100),
            treesCollectionView.bottomAnchor.constraint(equalTo: treesSection.bottomAnchor),
            
            // Gardens section
            gardensSectionTitle.topAnchor.constraint(equalTo: gardensSection.topAnchor, constant: 16),
            gardensSectionTitle.leadingAnchor.constraint(equalTo: gardensSection.leadingAnchor, constant: 16),
            
            gardensSubtitle.topAnchor.constraint(equalTo: gardensSectionTitle.bottomAnchor, constant: 4),
            gardensSubtitle.leadingAnchor.constraint(equalTo: gardensSection.leadingAnchor, constant: 16),
            
            gardensStack.topAnchor.constraint(equalTo: gardensSubtitle.bottomAnchor, constant: 12),
            gardensStack.leadingAnchor.constraint(equalTo: gardensSection.leadingAnchor),
            gardensStack.trailingAnchor.constraint(equalTo: gardensSection.trailingAnchor),
            gardensStack.bottomAnchor.constraint(equalTo: gardensSection.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupCollectionView() {
        treesCollectionView.dataSource = self
        treesCollectionView.delegate = self
        treesCollectionView.register(RedeemedTreeCell.self, forCellWithReuseIdentifier: RedeemedTreeCell.reuseId)
    }
    
    private func setupBindings() {
        viewModel.$archivedGardens
            .receive(on: DispatchQueue.main)
            .sink { [weak self] gardens in
                self?.updateGardensList(with: gardens)
            }
            .store(in: &cancellables)
        
        viewModel.$redeemedTrees
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.treesCollectionView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - UI Updates
    
    private func updateGardensList(with gardens: [ArchivedGarden]) {
        gardensStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for garden in gardens {
            let row = createGardenRow(garden: garden)
            gardensStack.addArrangedSubview(row)
        }
    }
    
    private func createGardenRow(garden: ArchivedGarden) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let iconView = UIImageView()
        iconView.image = UIImage(named: "tree_oak_adult")
        iconView.contentMode = .scaleAspectFit
        iconView.layer.cornerRadius = 8
        iconView.clipsToBounds = true
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let titleLabel = UILabel()
        titleLabel.text = garden.name
        titleLabel.font = .appTitleSmall
        titleLabel.textColor = .label
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = garden.status.subtitle
        subtitleLabel.font = .appCaption
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel
        chevron.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iconView)
        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)
        container.addSubview(chevron)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 64),
            
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 44),
            iconView.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            
            subtitleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 12),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            
            chevron.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            chevron.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    // MARK: - Actions
    
    @objc private func showSettings() {
        coordinator?.showSettings()
    }
}

// MARK: - UICollectionViewDataSource

extension ProfileViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.redeemedTrees.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RedeemedTreeCell.reuseId, for: indexPath) as? RedeemedTreeCell else {
            return UICollectionViewCell()
        }
        
        let tree = viewModel.redeemedTrees[indexPath.item]
        cell.configure(with: tree)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension ProfileViewController: UICollectionViewDelegate {}

// MARK: - Redeemed Tree Cell

private class RedeemedTreeCell: UICollectionViewCell {
    
    static let reuseId = "RedeemedTreeCell"
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.layer.cornerRadius = 12
        iv.clipsToBounds = true
        iv.backgroundColor = .systemGray5
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let overlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .appLabelBold
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let locationLabel: UILabel = {
        let label = UILabel()
        label.font = .appCaptionSmall
        label.textColor = .white.withAlphaComponent(0.8)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(overlay)
        contentView.addSubview(titleLabel)
        contentView.addSubview(locationLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            overlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            overlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            overlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.bottomAnchor.constraint(equalTo: locationLabel.topAnchor, constant: -2),
            
            locationLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            locationLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
        
        // Placeholder image
        imageView.image = UIImage(named: "tree_oak_adult")
    }
    
    func configure(with tree: RedeemedTree) {
        titleLabel.text = tree.providerName
        locationLabel.text = "📍 \(tree.location)"
    }
}
