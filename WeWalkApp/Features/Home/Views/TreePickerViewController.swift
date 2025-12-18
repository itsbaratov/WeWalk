//
//  TreePickerViewController.swift
//  WeWalkApp
//
//  Modal for selecting tree type
//

import UIKit

final class TreePickerViewController: UIViewController {
    
    // MARK: - Properties
    
    private var selectedTreeType: String
    private let onSelect: (String) -> Void
    private let treeTypes = TreeAssetRegistry.shared.treeTypes
    
    // MARK: - UI Elements
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        tv.backgroundColor = .systemGroupedBackground
        return tv
    }()
    
    // MARK: - Init
    
    init(selectedTreeType: String, onSelect: @escaping (String) -> Void) {
        self.selectedTreeType = selectedTreeType
        self.onSelect = onSelect
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Select Tree"
        view.backgroundColor = .systemGroupedBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissPicker)
        )
        
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(TreePickerCell.self, forCellReuseIdentifier: TreePickerCell.reuseId)
    }
    
    @objc private func dismissPicker() {
        dismiss(animated: true)
    }
}

// MARK: - UITableViewDataSource

extension TreePickerViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        treeTypes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TreePickerCell.reuseId, for: indexPath) as? TreePickerCell else {
            return UITableViewCell()
        }
        
        let tree = treeTypes[indexPath.row]
        let isSelected = tree.id == selectedTreeType
        cell.configure(with: tree, isSelected: isSelected)
        
        return cell
    }
}

// MARK: - UITableViewDelegate

extension TreePickerViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let tree = treeTypes[indexPath.row]
        selectedTreeType = tree.id
        tableView.reloadData()
        
        // Delay to show selection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.onSelect(tree.id)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        80
    }
}

// MARK: - Tree Picker Cell

private class TreePickerCell: UITableViewCell {
    
    static let reuseId = "TreePickerCell"
    
    private let treeImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .appTitleSmall
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .appCaption
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let rarityBadge: UILabel = {
        let label = UILabel()
        label.font = .appCaptionSmall
        label.textAlignment = .center
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let checkmarkView: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        iv.tintColor = .appMintGreen
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(treeImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(descriptionLabel)
        contentView.addSubview(rarityBadge)
        contentView.addSubview(checkmarkView)
        
        NSLayoutConstraint.activate([
            treeImageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            treeImageView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            treeImageView.widthAnchor.constraint(equalToConstant: 60),
            treeImageView.heightAnchor.constraint(equalToConstant: 60),
            
            nameLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            nameLabel.leadingAnchor.constraint(equalTo: treeImageView.trailingAnchor, constant: 12),
            
            rarityBadge.leadingAnchor.constraint(equalTo: nameLabel.trailingAnchor, constant: 8),
            rarityBadge.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            rarityBadge.heightAnchor.constraint(equalToConstant: 16),
            rarityBadge.widthAnchor.constraint(greaterThanOrEqualToConstant: 50),
            
            descriptionLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            descriptionLabel.leadingAnchor.constraint(equalTo: treeImageView.trailingAnchor, constant: 12),
            descriptionLabel.trailingAnchor.constraint(equalTo: checkmarkView.leadingAnchor, constant: -8),
            
            checkmarkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            checkmarkView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkView.widthAnchor.constraint(equalToConstant: 24),
            checkmarkView.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with tree: TreeTypeInfo, isSelected: Bool) {
        treeImageView.image = tree.image(for: .adult)
        nameLabel.text = tree.name
        descriptionLabel.text = tree.description
        
        // Rarity styling
        rarityBadge.text = " \(tree.rarity.displayName) "
        switch tree.rarity {
        case .common:
            rarityBadge.backgroundColor = .systemGray5
            rarityBadge.textColor = .secondaryLabel
        case .uncommon:
            rarityBadge.backgroundColor = .systemGreen.withAlphaComponent(0.2)
            rarityBadge.textColor = .systemGreen
        case .rare:
            rarityBadge.backgroundColor = .systemBlue.withAlphaComponent(0.2)
            rarityBadge.textColor = .systemBlue
        case .legendary:
            rarityBadge.backgroundColor = .systemPurple.withAlphaComponent(0.2)
            rarityBadge.textColor = .systemPurple
        }
        
        checkmarkView.isHidden = !isSelected
    }
}
