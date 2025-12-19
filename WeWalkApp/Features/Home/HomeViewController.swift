//
//  HomeViewController.swift
//  WeWalkApp
//
//  Main home screen with tree, progress ring, and stats
//

import UIKit
import Combine

final class HomeViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var coordinator: HomeCoordinator?
    private let viewModel: HomeViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Elements
    
    private let gradientLayer = CAGradientLayer()
    
    // Background view for grayish section below gradient
    private let whiteBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = .appPageBackground
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let headerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Home"
        label.font = .appTitleLarge
        label.textColor = .appTextOnDark
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Streak container on the right side - contains icon and count
    private let streakContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.appTealAccent.withAlphaComponent(0.4)
        view.layer.cornerRadius = 20
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let streakIconView: UIImageView = {
        let imageView = UIImageView()
        let config = UIImage.SymbolConfiguration(weight: .bold)
        imageView.image = UIImage(systemName: "bolt.fill", withConfiguration: config)
        imageView.tintColor = .appMintGreen
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let streakCountLabel: UILabel = {
        let label = UILabel()
        label.text = "0"
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .appTextOnDark
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let treeContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let progressRingView: ProgressRingView = {
        let view = ProgressRingView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let treeDisplayView: TreeDisplayView = {
        let view = TreeDisplayView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Combined steps label - "8,750 Steps" on single line
    private let stepsLabel: UILabel = {
        let label = UILabel()
        label.text = "0 Steps"
        label.font = .appDisplayLarge
        label.textColor = .appTextOnDark
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Progress label with grayish color
    private let progressLabel: UILabel = {
        let label = UILabel()
        label.text = "0% Daily Goal"
        label.font = .appBodyMedium
        label.textColor = UIColor.white.withAlphaComponent(0.6) // Grayish color
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsCardView: StatsCardView = {
        let view = StatsCardView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let weeklyChartView: WeeklyChartView = {
        let view = WeeklyChartView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Init
    
    init(viewModel: HomeViewModel) {
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
        setupActions()
        
        Task {
            await viewModel.requestHealthKitPermission()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateGradientFrame()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // White background at bottom
        view.addSubview(whiteBackgroundView)
        
        // Gradient layer
        gradientLayer.colors = UIColor.appBackgroundGradientColors
        gradientLayer.locations = [0.0, 0.5, 1.0]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, above: whiteBackgroundView.layer)
        
        // Header
        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        headerView.addSubview(streakContainerView)
        streakContainerView.addSubview(streakIconView)
        streakContainerView.addSubview(streakCountLabel)
        
        // Tree and progress
        view.addSubview(treeContainer)
        treeContainer.addSubview(progressRingView)
        treeContainer.addSubview(treeDisplayView)
        
        // Steps display
        view.addSubview(stepsLabel)
        view.addSubview(progressLabel)
        
        // Cards
        view.addSubview(statsCardView)
        view.addSubview(weeklyChartView)
        
        setupConstraints()
        
        progressRingView.addGlowEffect()
    }
    
    private func updateGradientFrame() {
        // Gradient ends at vertical center of stats card
        let gradientEndY = statsCardView.frame.midY
        if gradientEndY > 0 {
            gradientLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: gradientEndY)
        } else {
            // Fallback before layout
            gradientLayer.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height * 0.65)
        }
    }
    
    private func setupConstraints() {
        let padding = AppConstants.Layout.standardPadding
        let ringSize = AppConstants.Layout.progressRingSize
        
        NSLayoutConstraint.activate([
            // White background covers entire view
            whiteBackgroundView.topAnchor.constraint(equalTo: view.topAnchor),
            whiteBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            whiteBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            whiteBackgroundView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Header
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            headerView.heightAnchor.constraint(equalToConstant: 44),
            
            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            
            // Streak container - widened to fit icon and count
            streakContainerView.trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            streakContainerView.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            streakContainerView.heightAnchor.constraint(equalToConstant: 40),
            
            streakIconView.leadingAnchor.constraint(equalTo: streakContainerView.leadingAnchor, constant: 10),
            streakIconView.centerYAnchor.constraint(equalTo: streakContainerView.centerYAnchor),
            streakIconView.widthAnchor.constraint(equalToConstant: 20),
            streakIconView.heightAnchor.constraint(equalToConstant: 20),
            
            streakCountLabel.leadingAnchor.constraint(equalTo: streakIconView.trailingAnchor, constant: 4),
            streakCountLabel.trailingAnchor.constraint(equalTo: streakContainerView.trailingAnchor, constant: -10),
            streakCountLabel.centerYAnchor.constraint(equalTo: streakContainerView.centerYAnchor),
            
            // Tree Container
            treeContainer.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 16),
            treeContainer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            treeContainer.widthAnchor.constraint(equalToConstant: ringSize),
            treeContainer.heightAnchor.constraint(equalToConstant: ringSize),
            
            progressRingView.topAnchor.constraint(equalTo: treeContainer.topAnchor),
            progressRingView.leadingAnchor.constraint(equalTo: treeContainer.leadingAnchor),
            progressRingView.trailingAnchor.constraint(equalTo: treeContainer.trailingAnchor),
            progressRingView.bottomAnchor.constraint(equalTo: treeContainer.bottomAnchor),
            
            treeDisplayView.centerXAnchor.constraint(equalTo: treeContainer.centerXAnchor),
            treeDisplayView.centerYAnchor.constraint(equalTo: treeContainer.centerYAnchor),
            treeDisplayView.widthAnchor.constraint(equalToConstant: ringSize - 40),
            treeDisplayView.heightAnchor.constraint(equalToConstant: ringSize - 40),
            
            // Steps - Combined label
            stepsLabel.topAnchor.constraint(equalTo: treeContainer.bottomAnchor, constant: 12),
            stepsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            progressLabel.topAnchor.constraint(equalTo: stepsLabel.bottomAnchor, constant: 4),
            progressLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Stats Card
            statsCardView.topAnchor.constraint(equalTo: progressLabel.bottomAnchor, constant: 20),
            statsCardView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            statsCardView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            statsCardView.heightAnchor.constraint(equalToConstant: 80),
            
            // Weekly Chart - fills remaining space
            weeklyChartView.topAnchor.constraint(equalTo: statsCardView.bottomAnchor, constant: 12),
            weeklyChartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding),
            weeklyChartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding),
            weeklyChartView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
    }
    
    private func setupBindings() {
        // Steps - Combined with "Steps" text
        viewModel.$steps
            .receive(on: DispatchQueue.main)
            .map { NumberFormatter.localizedString(from: NSNumber(value: $0), number: .decimal) + " Steps" }
            .sink { [weak self] text in
                self?.stepsLabel.text = text
            }
            .store(in: &cancellables)
        
        // Progress
        viewModel.$progress
            .receive(on: DispatchQueue.main)
            .sink { [weak self] progress in
                self?.progressRingView.setProgress(CGFloat(min(progress, 1.0)), animated: true)
                self?.progressLabel.text = String(format: "%.0f%% Daily Goal", min(progress * 100, 999))
            }
            .store(in: &cancellables)
        
        // Stats
        Publishers.CombineLatest(viewModel.$distance, viewModel.$calories)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] distance, calories in
                guard let self = self else { return }
                self.statsCardView.updateStats(
                    distance: self.viewModel.formattedDistance,
                    calories: self.viewModel.formattedCalories
                )
            }
            .store(in: &cancellables)
        
        // Tree
        Publishers.CombineLatest3(
            viewModel.$currentTreeType,
            viewModel.$currentGrowthStage,
            viewModel.$isReadyToPlant
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] treeType, stage, isReady in
            self?.treeDisplayView.updateTree(
                treeType: treeType,
                stage: stage,
                isReady: isReady,
                animated: true
            )
        }
        .store(in: &cancellables)
        
        // Streak - Update icon color
        viewModel.$streakCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] streak in
                self?.updateStreakDisplay(streak: streak)
            }
            .store(in: &cancellables)
        
        // Weekly data
        viewModel.$weeklyData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.weeklyChartView.updateChart(with: data)
            }
            .store(in: &cancellables)
    }
    
    private func setupActions() {
        let streakTap = UITapGestureRecognizer(target: self, action: #selector(streakTapped))
        streakContainerView.addGestureRecognizer(streakTap)
        streakContainerView.isUserInteractionEnabled = true
        
        treeDisplayView.onTap = { [weak self] in
            self?.showTreePicker()
        }
    }
    
    // MARK: - Actions
    
    @objc private func streakTapped() {
        coordinator?.showProgressAndBadges()
    }
    
    private func showTreePicker() {
        guard viewModel.canChangeTree else {
            // Show alert that tree is locked
            let alert = UIAlertController(
                title: "Tree Locked",
                message: "Your tree is locked once you reach 100% of your daily goal. It's ready to plant!",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        coordinator?.showTreePicker(
            currentTreeType: viewModel.currentTreeType?.id ?? "oak"
        ) { [weak self] selectedId in
            self?.viewModel.selectTree(selectedId)
        }
    }
    
    // MARK: - UI Updates
    
    private func updateStreakDisplay(streak: Int) {
        streakIconView.tintColor = streak > 0 ? .appMintGreen : .appSecondaryTextOnDark
        streakCountLabel.text = "\(streak)"
    }
}
