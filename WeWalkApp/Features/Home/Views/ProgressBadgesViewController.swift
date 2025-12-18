//
//  ProgressBadgesViewController.swift
//  WeWalkApp
//
//  Modal showing streak progress and badges
//

import UIKit
import Combine

final class ProgressBadgesViewController: UIViewController {
    
    // MARK: - Properties
    
    private let streakService = StreakService.shared
    
    // MARK: - UI Elements
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
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
    
    private let streakCard: UIView = {
        let view = UIView()
        view.backgroundColor = .appPrimaryGreen
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let streakNumberLabel: UILabel = {
        let label = UILabel()
        label.font = .appDisplayLarge
        label.textColor = .appTextOnDark
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let streakTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Day Streak"
        label.font = .appTitleMedium
        label.textColor = .appSecondaryTextOnDark
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let badgesHeaderLabel: UILabel = {
        let label = UILabel()
        label.text = "Badges"
        label.font = .appTitleLarge
        label.textColor = .label
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let badgesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumInteritemSpacing = 16
        layout.minimumLineSpacing = 16
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.translatesAutoresizingMaskIntoConstraints = false
        return cv
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadData()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Progress & Badges"
        view.backgroundColor = .systemBackground
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(dismissModal)
        )
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        // Streak card
        streakCard.addSubview(streakNumberLabel)
        streakCard.addSubview(streakTitleLabel)
        contentStack.addArrangedSubview(streakCard)
        
        // Badges
        contentStack.addArrangedSubview(badgesHeaderLabel)
        contentStack.addArrangedSubview(badgesCollectionView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 24),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            
            streakCard.heightAnchor.constraint(equalToConstant: 120),
            
            streakNumberLabel.centerXAnchor.constraint(equalTo: streakCard.centerXAnchor),
            streakNumberLabel.centerYAnchor.constraint(equalTo: streakCard.centerYAnchor, constant: -8),
            
            streakTitleLabel.topAnchor.constraint(equalTo: streakNumberLabel.bottomAnchor),
            streakTitleLabel.centerXAnchor.constraint(equalTo: streakCard.centerXAnchor),
            
            badgesCollectionView.heightAnchor.constraint(equalToConstant: 400)
        ])
        
        badgesCollectionView.dataSource = self
        badgesCollectionView.delegate = self
        badgesCollectionView.register(BadgeCell.self, forCellWithReuseIdentifier: BadgeCell.reuseId)
    }
    
    private func loadData() {
        let streakData = streakService.currentStreak.value
        streakNumberLabel.text = "\(streakData.currentStreak)"
    }
    
    @objc private func dismissModal() {
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource

extension ProgressBadgesViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        BadgeMilestone.allMilestones.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: BadgeCell.reuseId, for: indexPath) as? BadgeCell else {
            return UICollectionViewCell()
        }
        
        let milestone = BadgeMilestone.allMilestones[indexPath.item]
        let isUnlocked = streakService.currentStreak.value.longestStreak >= milestone.id
        cell.configure(with: milestone, isUnlocked: isUnlocked)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ProgressBadgesViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (collectionView.bounds.width - 32) / 3
        return CGSize(width: width, height: width + 30)
    }
}

// MARK: - Badge Cell

private class BadgeCell: UICollectionViewCell {
    
    static let reuseId = "BadgeCell"
    
    private let iconView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .appLabelBold
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .appCaptionSmall
        label.textAlignment = .center
        label.numberOfLines = 2
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
        contentView.layer.cornerRadius = 12
        contentView.layer.borderWidth = 2
        
        contentView.addSubview(iconView)
        contentView.addSubview(dayLabel)
        contentView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 40),
            iconView.heightAnchor.constraint(equalToConstant: 40),
            
            dayLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 4),
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 2),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4)
        ])
    }
    
    func configure(with milestone: BadgeMilestone, isUnlocked: Bool) {
        dayLabel.text = "\(milestone.id)"
        nameLabel.text = milestone.name
        
        if isUnlocked {
            contentView.backgroundColor = .appMintGreen.withAlphaComponent(0.2)
            contentView.layer.borderColor = UIColor.appMintGreen.cgColor
            iconView.image = UIImage(systemName: "flame.fill")
            iconView.tintColor = .appMintGreen
            dayLabel.textColor = .appPrimaryGreen
            nameLabel.textColor = .label
        } else {
            contentView.backgroundColor = .systemGray6
            contentView.layer.borderColor = UIColor.systemGray4.cgColor
            iconView.image = UIImage(systemName: "lock.fill")
            iconView.tintColor = .systemGray3
            dayLabel.textColor = .systemGray3
            nameLabel.textColor = .systemGray3
        }
    }
}
