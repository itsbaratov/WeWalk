//
//  PermissionsViewController.swift
//  WeWalkApp
//
//  HealthKit permissions request screen
//

import UIKit
import HealthKit

final class PermissionsViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var coordinator: OnboardingCoordinator?
    private let healthKitService = HealthKitService()
    
    // MARK: - UI Elements
    
    private let iconImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(systemName: "heart.fill")
        iv.tintColor = .appMintGreen
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Health Access"
        label.font = .appTitleLarge
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "WeWalk needs access to your step count, distance, and calories to track your progress and grow your virtual trees."
        label.font = .appBodyMedium
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let allowButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Allow Access", for: .normal)
        button.titleLabel?.font = .appTitleMedium
        button.backgroundColor = .appPrimaryGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let skipButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Skip for now", for: .normal)
        button.titleLabel?.font = .appBodyMedium
        button.setTitleColor(.secondaryLabel, for: .normal)
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
        
        view.addSubview(iconImageView)
        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(allowButton)
        view.addSubview(skipButton)
        
        NSLayoutConstraint.activate([
            iconImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 80),
            iconImageView.widthAnchor.constraint(equalToConstant: 80),
            iconImageView.heightAnchor.constraint(equalToConstant: 80),
            
            titleLabel.topAnchor.constraint(equalTo: iconImageView.bottomAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            descriptionLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            descriptionLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            descriptionLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            allowButton.bottomAnchor.constraint(equalTo: skipButton.topAnchor, constant: -16),
            allowButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            allowButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            allowButton.heightAnchor.constraint(equalToConstant: 56),
            
            skipButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            skipButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        allowButton.addTarget(self, action: #selector(allowTapped), for: .touchUpInside)
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func allowTapped() {
        Task {
            do {
                _ = try await healthKitService.requestAuthorization()
                await MainActor.run {
                    coordinator?.showGoalSetupStep()
                }
            } catch {
                await MainActor.run {
                    coordinator?.showGoalSetupStep()
                }
            }
        }
    }
    
    @objc private func skipTapped() {
        coordinator?.showGoalSetupStep()
    }
}
