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
    
    // Header section with streak info (no background, clean design)
    private let headerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let boltIcon: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "bolt.fill")
        iv.tintColor = .secondaryLabel
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let streakNumberLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let daysLabel: UILabel = {
        let label = UILabel()
        label.text = "days"
        label.font = .systemFont(ofSize: 28, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "of hitting step goal"
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .tertiaryLabel
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
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 32, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.alwaysBounceVertical = true
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
        
        // Add subviews
        view.addSubview(headerContainer)
        headerContainer.addSubview(boltIcon)
        headerContainer.addSubview(streakNumberLabel)
        headerContainer.addSubview(daysLabel)
        headerContainer.addSubview(subtitleLabel)
        
        view.addSubview(badgesHeaderLabel)
        view.addSubview(badgesCollectionView)
        
        NSLayoutConstraint.activate([
            // Header container - fixed at top
            headerContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            
            // Bolt icon
            boltIcon.topAnchor.constraint(equalTo: headerContainer.topAnchor, constant: 24),
            boltIcon.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            boltIcon.widthAnchor.constraint(equalToConstant: 48),
            boltIcon.heightAnchor.constraint(equalToConstant: 48),
            
            // Number + "days" on same line
            streakNumberLabel.topAnchor.constraint(equalTo: boltIcon.bottomAnchor, constant: 8),
            streakNumberLabel.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor, constant: -30),
            
            daysLabel.firstBaselineAnchor.constraint(equalTo: streakNumberLabel.firstBaselineAnchor),
            daysLabel.leadingAnchor.constraint(equalTo: streakNumberLabel.trailingAnchor, constant: 4),
            
            // Subtitle
            subtitleLabel.topAnchor.constraint(equalTo: streakNumberLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: headerContainer.centerXAnchor),
            subtitleLabel.bottomAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: -24),
            
            // Badges header
            badgesHeaderLabel.topAnchor.constraint(equalTo: headerContainer.bottomAnchor, constant: 24),
            badgesHeaderLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            
            // Collection view - fills remaining space to bottom
            badgesCollectionView.topAnchor.constraint(equalTo: badgesHeaderLabel.bottomAnchor, constant: 12),
            badgesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            badgesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            badgesCollectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        badgesCollectionView.dataSource = self
        badgesCollectionView.delegate = self
        badgesCollectionView.register(BadgeCell.self, forCellWithReuseIdentifier: BadgeCell.reuseId)
    }
    
    private func loadData() {
        let streakData = streakService.currentStreak.value
        let currentStreak = streakData.currentStreak
        streakNumberLabel.text = "\(currentStreak)"
        
        // Apply active styling when streak >= 1
        if currentStreak >= 1 {
            applyActiveStyle()
            startPulseAnimation()
        } else {
            applyInactiveStyle()
        }
    }
    
    private func applyActiveStyle() {
        boltIcon.tintColor = .appMintGreen
        streakNumberLabel.textColor = .appMintGreen
        daysLabel.textColor = .appMintGreen
        subtitleLabel.textColor = .appMintGreen
    }
    
    private func applyInactiveStyle() {
        boltIcon.tintColor = .secondaryLabel
        streakNumberLabel.textColor = .secondaryLabel
        daysLabel.textColor = .secondaryLabel
        subtitleLabel.textColor = .tertiaryLabel
    }
    
    private func startPulseAnimation() {
        // Subtle pulsating animation on the bolt icon
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.15
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        
        boltIcon.layer.add(pulseAnimation, forKey: "pulse")
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
        let width = (collectionView.bounds.width - 56) / 3
        return CGSize(width: width, height: width + 40)
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
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
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
            iconView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            iconView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 36),
            iconView.heightAnchor.constraint(equalToConstant: 36),
            
            dayLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 8),
            dayLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: dayLabel.bottomAnchor, constant: 4),
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
            iconView.image = UIImage(systemName: "bolt.fill")
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
