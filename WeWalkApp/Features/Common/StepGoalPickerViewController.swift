//
//  StepGoalPickerViewController.swift
//  WeWalkApp
//
//  Created by WeWalk Team on 2025-12-18.
//

import UIKit

protocol StepGoalPickerDelegate: AnyObject {
    func didUpdateDailyGoal(_ newGoal: Int)
}

final class StepGoalPickerViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var delegate: StepGoalPickerDelegate?
    private var selectedGoal: Int
    private let minimumSteps = AppConstants.DailyGoal.minimumSteps
    private let maximumSteps = AppConstants.DailyGoal.maximumSteps
    private let increment = AppConstants.DailyGoal.stepIncrement
    
    private var goalOptions: [Int] {
        stride(from: minimumSteps, through: maximumSteps, by: increment).map { $0 }
    }
    
    // MARK: - UI Elements
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .appPageBackground
        view.layer.cornerRadius = 24
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Set Daily Goal"
        label.font = .appTitleLarge
        label.textColor = .label
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
        let originalSelector = Selector("setHighlightsToday:")
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        picker.translatesAutoresizingMaskIntoConstraints = false
        return picker
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save Goal", for: .normal)
        button.titleLabel?.font = .appTitleMedium
        button.backgroundColor = .appPrimaryGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 16
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Init
    
    init(currentGoal: Int) {
        self.selectedGoal = currentGoal
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
        if let sheet = sheetPresentationController {
            sheet.detents = [.medium()]
            sheet.prefersGrabberVisible = true
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        selectinitialRow()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(titleLabel)
        view.addSubview(pickerContainer)
        pickerContainer.addSubview(pickerView)
        view.addSubview(saveButton)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            pickerContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 32),
            pickerContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            pickerContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            pickerContainer.heightAnchor.constraint(equalToConstant: 200),
            
            pickerView.topAnchor.constraint(equalTo: pickerContainer.topAnchor),
            pickerView.leadingAnchor.constraint(equalTo: pickerContainer.leadingAnchor),
            pickerView.trailingAnchor.constraint(equalTo: pickerContainer.trailingAnchor),
            pickerView.bottomAnchor.constraint(equalTo: pickerContainer.bottomAnchor),
            
            saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            saveButton.heightAnchor.constraint(equalToConstant: 56)
        ])
        
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
    }
    
    private func selectinitialRow() {
        // Find closest match or default
        if let index = goalOptions.firstIndex(where: { $0 >= selectedGoal }) {
            pickerView.selectRow(index, inComponent: 0, animated: false)
        } else {
            // Default to middle if no match
            pickerView.selectRow(goalOptions.count / 2, inComponent: 0, animated: false)
        }
    }
    
    // MARK: - Actions
    
    @objc private func saveTapped() {
        let row = pickerView.selectedRow(inComponent: 0)
        let newGoal = goalOptions[row]
        
        // Save to UserDefaults
        UserDefaults.standard.set(newGoal, forKey: "dailyGoal")
        
        // Notify
        NotificationCenter.default.post(name: .dailyGoalChanged, object: nil, userInfo: ["goal": newGoal])
        delegate?.didUpdateDailyGoal(newGoal)
        
        dismiss(animated: true)
    }
}

// MARK: - UIPickerViewDataSource, UIPickerViewDelegate

extension StepGoalPickerViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return goalOptions.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let value = goalOptions[row]
        return NumberFormatter.localizedString(from: NSNumber(value: value), number: .decimal)
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
}
