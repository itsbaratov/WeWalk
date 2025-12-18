//
//  GoalSetupViewController.swift
//  WeWalkApp
//
//  Daily goal setup screen
//

import UIKit

final class GoalSetupViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var coordinator: OnboardingCoordinator?
    private var dailyGoal: Int = AppConstants.DailyGoal.defaultSteps
    
    // MARK: - UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Set Your Daily Goal"
        label.font = .appTitleLarge
        label.textColor = .label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let goalLabel: UILabel = {
        let label = UILabel()
        label.text = "10,000"
        label.font = .appDisplayLarge
        label.textColor = .appPrimaryGreen
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let stepsLabel: UILabel = {
        let label = UILabel()
        label.text = "steps per day"
        label.font = .appBodyLarge
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let slider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = Float(AppConstants.DailyGoal.minimumSteps)
        slider.maximumValue = Float(AppConstants.DailyGoal.maximumSteps)
        slider.value = Float(AppConstants.DailyGoal.defaultSteps)
        slider.tintColor = .appMintGreen
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Continue", for: .normal)
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
        view.addSubview(goalLabel)
        view.addSubview(stepsLabel)
        view.addSubview(slider)
        view.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            goalLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            goalLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stepsLabel.topAnchor.constraint(equalTo: goalLabel.bottomAnchor, constant: 8),
            stepsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            slider.topAnchor.constraint(equalTo: stepsLabel.bottomAnchor, constant: 40),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        slider.addTarget(self, action: #selector(sliderChanged), for: .valueChanged)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func sliderChanged() {
        let step = AppConstants.DailyGoal.stepIncrement
        let roundedValue = Int(slider.value / Float(step)) * step
        dailyGoal = roundedValue
        goalLabel.text = NumberFormatter.localizedString(from: NSNumber(value: roundedValue), number: .decimal)
    }
    
    @objc private func continueTapped() {
        UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal")
        coordinator?.showTreeSelectionStep()
    }
}
