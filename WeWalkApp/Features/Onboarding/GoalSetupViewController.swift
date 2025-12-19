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
    
    private let minimumSteps = AppConstants.DailyGoal.minimumSteps
    private let maximumSteps = AppConstants.DailyGoal.maximumSteps
    private let increment = AppConstants.DailyGoal.stepIncrement
    
    private var goalOptions: [Int] {
        stride(from: minimumSteps, through: maximumSteps, by: increment).map { $0 }
    }
    
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
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "How many steps do you want to walk?"
        label.font = .appBodyMedium
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let pickerContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 16
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var pickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private let goalDisplayLabel: UILabel = {
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
        selectDefaultRow()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(goalDisplayLabel)
        view.addSubview(stepsLabel)
        view.addSubview(pickerContainer)
        pickerContainer.addSubview(pickerView)
        view.addSubview(continueButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            goalDisplayLabel.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 40),
            goalDisplayLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            stepsLabel.topAnchor.constraint(equalTo: goalDisplayLabel.bottomAnchor, constant: 4),
            stepsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            pickerContainer.topAnchor.constraint(equalTo: stepsLabel.bottomAnchor, constant: 40),
            pickerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            pickerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            pickerContainer.heightAnchor.constraint(equalToConstant: 180),
            
            pickerView.topAnchor.constraint(equalTo: pickerContainer.topAnchor),
            pickerView.leadingAnchor.constraint(equalTo: pickerContainer.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: pickerContainer.trailingAnchor),
            pickerView.bottomAnchor.constraint(equalTo: pickerContainer.bottomAnchor),
            
            continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            continueButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
    }
    
    private func selectDefaultRow() {
        if let index = goalOptions.firstIndex(of: AppConstants.DailyGoal.defaultSteps) {
            pickerView.selectRow(index, inComponent: 0, animated: false)
            updateLabels(value: AppConstants.DailyGoal.defaultSteps)
        }
    }
    
    private func updateLabels(value: Int) {
        dailyGoal = value
        goalDisplayLabel.text = NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
    }
    
    // MARK: - Actions
    
    @objc private func continueTapped() {
        UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal")
        NotificationCenter.default.post(name: .dailyGoalChanged, object: nil, userInfo: ["goal": dailyGoal])
        coordinator?.showTreeSelectionStep()
    }
}

// MARK: - UIPickerViewDataSource, UIPickerViewDelegate

extension GoalSetupViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return goalOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        // Return nil to use viewForRow
        return nil
    }
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 44
    }
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = (view as? UILabel) ?? UILabel()
        label.font = .appTitleMedium
        label.textAlignment = .center
        label.textColor = .label
        
        let value = goalOptions[row]
        label.text = NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
        
        return label
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let value = goalOptions[row]
        updateLabels(value: value)
    }
}
