//
//  TreeSelectionViewController.swift
//  WeWalkApp
//
//  Initial tree selection during onboarding
//

import UIKit

final class TreeSelectionViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var coordinator: OnboardingCoordinator?
    private let treeTypes = TreeAssetRegistry.shared.treeTypes
    private var selectedTreeId: String = "oak"
    
    // MARK: - UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose Your First Tree"
        label.font = .appTitleLarge
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    private let startButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Walking", for: .normal)
        button.titleLabel?.font = .appTitleMedium
        button.backgroundColor = .appPrimaryGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(collectionView)
        view.addSubview(startButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            collectionView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 24),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            collectionView.bottomAnchor.constraint(equalTo: startButton.topAnchor, constant: -24),
            
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            startButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(TreeSelectionCell.self, forCellWithReuseIdentifier: TreeSelectionCell.reuseId)
        
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func startTapped() {
        UserDefaults.standard.set(selectedTreeId, forKey: "selectedTreeType")
        coordinator?.completeOnboarding()
    }
}

// MARK: - UICollectionViewDataSource

extension TreeSelectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        treeTypes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: TreeSelectionCell.reuseId, for: indexPath) as? TreeSelectionCell else {
            return UICollectionViewCell()
        }
        
        let tree = treeTypes[indexPath.item]
        cell.configure(with: tree, isSelected: tree.id == selectedTreeId)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension TreeSelectionViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectedTreeId = treeTypes[indexPath.item].id
        collectionView.reloadData()
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TreeSelectionViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 32) / 2
        return CGSize(width: width, height: width + 40)
    }
}

// MARK: - Tree Selection Cell

private class TreeSelectionCell: UICollectionViewCell {
    
    static let reuseId = "TreeSelectionCell"
    
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .appLabelBold
        label.textAlignment = .center
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
        contentView.layer.cornerRadius = 16
        contentView.layer.borderWidth = 3
        
        contentView.addSubview(imageView)
        contentView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            imageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 80),
            imageView.heightAnchor.constraint(equalToConstant: 80),
            
            nameLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 8),
            nameLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor)
        ])
    }
    
    func configure(with tree: TreeTypeInfo, isSelected: Bool) {
        imageView.image = tree.image(for: .adult)
        nameLabel.text = tree.name
        
        if isSelected {
            contentView.backgroundColor = .appMintGreen.withAlphaComponent(0.2)
            contentView.layer.borderColor = UIColor.appMintGreen.cgColor
            nameLabel.textColor = .appPrimaryGreen
        } else {
            contentView.backgroundColor = .systemGray6
            contentView.layer.borderColor = UIColor.clear.cgColor
            nameLabel.textColor = .label
        }
    }
}
