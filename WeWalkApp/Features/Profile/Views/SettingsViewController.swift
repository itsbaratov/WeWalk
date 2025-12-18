//
//  SettingsViewController.swift
//  WeWalkApp
//
//  Settings screen with appearance toggle
//

import UIKit
import Combine

final class SettingsViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let tableView: UITableView = {
        let tv = UITableView(frame: .zero, style: .insetGrouped)
        tv.translatesAutoresizingMaskIntoConstraints = false
        return tv
    }()
    
    private enum Section: Int, CaseIterable {
        case appearance
        case goal
        case data
        case about
    }
    
    private let themeManager = ThemeManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Settings"
        view.backgroundColor = .appSettingsBackground
        
        view.addSubview(tableView)
        tableView.backgroundColor = .appSettingsBackground
        
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    private func setupBindings() {
        themeManager.$currentTheme
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource

extension SettingsViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section) {
        case .appearance: return AppTheme.allCases.count
        case .goal: return 1
        case .data: return 2
        case .about: return 2
        case .none: return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        cell.backgroundColor = .appSettingsCellBackground
        
        switch Section(rawValue: indexPath.section) {
        case .appearance:
            let theme = AppTheme.allCases[indexPath.row]
            cell.textLabel?.text = theme.displayName
            cell.textLabel?.textColor = .appTextOnLight
            cell.accessoryType = themeManager.currentTheme == theme ? .checkmark : .none
            cell.tintColor = .appMintGreen
            
        case .goal:
            cell.textLabel?.text = "Daily Step Goal"
            cell.textLabel?.textColor = .appTextOnLight
            let goal = UserDefaults.standard.integer(forKey: "dailyGoal")
            cell.detailTextLabel?.text = NumberFormatter.localizedString(from: NSNumber(value: goal > 0 ? goal : 10000), number: .decimal)
            cell.detailTextLabel?.textColor = .appSecondaryTextOnLight
            cell.accessoryType = .disclosureIndicator
            
        case .data:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Export Data"
                cell.textLabel?.textColor = .appTextOnLight
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = "Delete All Data"
                cell.textLabel?.textColor = .systemRed
            }
            
        case .about:
            if indexPath.row == 0 {
                cell.textLabel?.text = "Privacy Policy"
                cell.textLabel?.textColor = .appTextOnLight
                cell.accessoryType = .disclosureIndicator
            } else {
                cell.textLabel?.text = "Version"
                cell.textLabel?.textColor = .appTextOnLight
                cell.detailTextLabel?.text = "1.0.0"
                cell.detailTextLabel?.textColor = .appSecondaryTextOnLight
            }
            
        case .none:
            break
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch Section(rawValue: section) {
        case .appearance: return "Appearance"
        case .goal: return "Goal"
        case .data: return "Data"
        case .about: return "About"
        case .none: return nil
        }
    }
}

// MARK: - UITableViewDelegate

extension SettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch Section(rawValue: indexPath.section) {
        case .appearance:
            let theme = AppTheme.allCases[indexPath.row]
            themeManager.setTheme(theme)
            
        case .data:
            if indexPath.row == 1 {
                showDeleteConfirmation()
            }
        default:
            break
        }
    }
    
    private func showDeleteConfirmation() {
        let alert = UIAlertController(
            title: "Delete All Data",
            message: "This will permanently delete all your progress, trees, and gardens. This action cannot be undone.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
            // Delete all data
            UserDefaults.standard.removeObject(forKey: "dailyGoal")
            UserDefaults.standard.removeObject(forKey: "currentGrowingTree")
            UserDefaults.standard.removeObject(forKey: "currentStreak")
            UserDefaults.standard.removeObject(forKey: "longestStreak")
            UserDefaults.standard.removeObject(forKey: "onboardingCompleted")
        })
        
        present(alert, animated: true)
    }
}
