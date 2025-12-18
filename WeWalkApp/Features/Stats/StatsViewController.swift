//
//  StatsViewController.swift
//  WeWalkApp
//
//  Stats screen with charts and averages
//

import UIKit
import Combine

final class StatsViewController: UIViewController {
    
    // MARK: - Properties
    
    weak var coordinator: StatsCoordinator?
    private let viewModel: StatsViewModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - UI Elements
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let segmentedControl: UISegmentedControl = {
        let items = TimeRange.allCases.map { $0.rawValue }
        let sc = UISegmentedControl(items: items)
        sc.selectedSegmentIndex = 0
        sc.translatesAutoresizingMaskIntoConstraints = false
        return sc
    }()
    
    private let chartCard: UIView = {
        let view = UIView()
        view.backgroundColor = .appCardBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.appCardShadow.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let chartStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .bottom
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let hourlyCard: UIView = {
        let view = UIView()
        view.backgroundColor = .appCardBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.appCardShadow.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let hourlyTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Hourly walking trend"
        label.font = .appTitleSmall
        label.textColor = .appTextOnLight
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let hourlyChartStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 2
        stack.alignment = .bottom
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let averagesCard: UIView = {
        let view = UIView()
        view.backgroundColor = .appCardBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.appCardShadow.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowOpacity = 1
        view.layer.shadowRadius = 8
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let averagesTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Average Steps"
        label.font = .appTitleSmall
        label.textColor = .appTextOnLight
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let averagesStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // MARK: - Init
    
    init(viewModel: StatsViewModel) {
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
        
        Task {
            await viewModel.loadInitialData()
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        title = "Stats"
        view.backgroundColor = .appPageBackground
        
        navigationController?.navigationBar.prefersLargeTitles = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        contentStack.addArrangedSubview(segmentedControl)
        contentStack.addArrangedSubview(chartCard)
        contentStack.addArrangedSubview(hourlyCard)
        contentStack.addArrangedSubview(averagesCard)
        
        // Chart card
        chartCard.addSubview(chartStack)
        
        // Hourly card
        hourlyCard.addSubview(hourlyTitleLabel)
        hourlyCard.addSubview(hourlyChartStack)
        
        // Averages card
        averagesCard.addSubview(averagesTitleLabel)
        averagesCard.addSubview(averagesStack)
        
        setupConstraints()
        
        segmentedControl.addTarget(self, action: #selector(timeRangeChanged), for: .valueChanged)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
            
            chartCard.heightAnchor.constraint(equalToConstant: 200),
            chartStack.topAnchor.constraint(equalTo: chartCard.topAnchor, constant: 16),
            chartStack.leadingAnchor.constraint(equalTo: chartCard.leadingAnchor, constant: 16),
            chartStack.trailingAnchor.constraint(equalTo: chartCard.trailingAnchor, constant: -16),
            chartStack.bottomAnchor.constraint(equalTo: chartCard.bottomAnchor, constant: -32),
            
            hourlyCard.heightAnchor.constraint(equalToConstant: 180),
            hourlyTitleLabel.topAnchor.constraint(equalTo: hourlyCard.topAnchor, constant: 16),
            hourlyTitleLabel.leadingAnchor.constraint(equalTo: hourlyCard.leadingAnchor, constant: 16),
            hourlyChartStack.topAnchor.constraint(equalTo: hourlyTitleLabel.bottomAnchor, constant: 12),
            hourlyChartStack.leadingAnchor.constraint(equalTo: hourlyCard.leadingAnchor, constant: 16),
            hourlyChartStack.trailingAnchor.constraint(equalTo: hourlyCard.trailingAnchor, constant: -16),
            hourlyChartStack.bottomAnchor.constraint(equalTo: hourlyCard.bottomAnchor, constant: -16),
            
            averagesCard.heightAnchor.constraint(equalToConstant: 100),
            averagesTitleLabel.topAnchor.constraint(equalTo: averagesCard.topAnchor, constant: 16),
            averagesTitleLabel.leadingAnchor.constraint(equalTo: averagesCard.leadingAnchor, constant: 16),
            averagesStack.topAnchor.constraint(equalTo: averagesTitleLabel.bottomAnchor, constant: 8),
            averagesStack.leadingAnchor.constraint(equalTo: averagesCard.leadingAnchor, constant: 16),
            averagesStack.trailingAnchor.constraint(equalTo: averagesCard.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupBindings() {
        viewModel.$chartData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.updateChart(with: data)
            }
            .store(in: &cancellables)
        
        viewModel.$hourlyData
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.updateHourlyChart(with: data)
            }
            .store(in: &cancellables)
        
        Publishers.CombineLatest4(
            viewModel.$averageDaily,
            viewModel.$averageWeekly,
            viewModel.$totalMonthly,
            viewModel.$totalYearly
        )
        .receive(on: DispatchQueue.main)
        .sink { [weak self] daily, weekly, monthly, yearly in
            self?.updateAverages(daily: daily, weekly: weekly, monthly: monthly, yearly: yearly)
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Actions
    
    @objc private func timeRangeChanged() {
        viewModel.selectedTimeRange = TimeRange.allCases[segmentedControl.selectedSegmentIndex]
    }
    
    // MARK: - UI Updates
    
    private func updateChart(with data: [ChartDataPoint]) {
        chartStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let maxValue = data.map { $0.value }.max() ?? 1
        
        for point in data {
            let barView = createChartBar(point: point, maxValue: maxValue)
            chartStack.addArrangedSubview(barView)
        }
    }
    
    private func createChartBar(point: ChartDataPoint, maxValue: Int) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let bar = UIView()
        bar.layer.cornerRadius = 4
        bar.translatesAutoresizingMaskIntoConstraints = false
        
        switch point.color {
        case .success: bar.backgroundColor = .appStatusSuccess
        case .warning: bar.backgroundColor = .appStatusWarning
        case .risk: bar.backgroundColor = .appStatusRisk
        }
        
        let label = UILabel()
        label.text = point.label
        label.font = .appCaptionSmall
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(bar)
        container.addSubview(label)
        
        let heightRatio = CGFloat(point.value) / CGFloat(maxValue)
        let barHeight = max(4, heightRatio * 100)
        
        NSLayoutConstraint.activate([
            bar.bottomAnchor.constraint(equalTo: label.topAnchor, constant: -4),
            bar.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 4),
            bar.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -4),
            bar.heightAnchor.constraint(equalToConstant: barHeight),
            
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            label.centerXAnchor.constraint(equalTo: container.centerXAnchor)
        ])
        
        return container
    }
    
    private func updateHourlyChart(with data: [Int: Int]) {
        hourlyChartStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let maxValue = data.values.max() ?? 1
        
        for hour in 0..<24 {
            let steps = data[hour] ?? 0
            let heightRatio = CGFloat(steps) / CGFloat(maxValue)
            
            let bar = UIView()
            bar.backgroundColor = .appMintGreen
            bar.layer.cornerRadius = 2
            bar.translatesAutoresizingMaskIntoConstraints = false
            
            let container = UIView()
            container.addSubview(bar)
            
            NSLayoutConstraint.activate([
                bar.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                bar.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                bar.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                bar.heightAnchor.constraint(equalTo: container.heightAnchor, multiplier: max(0.05, heightRatio))
            ])
            
            hourlyChartStack.addArrangedSubview(container)
        }
    }
    
    private func updateAverages(daily: Int, weekly: Int, monthly: Int, yearly: Int) {
        averagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        let items = [
            ("Day", formatNumber(daily)),
            ("Week", formatNumber(weekly)),
            ("Month", formatLargeNumber(monthly)),
            ("Year", formatLargeNumber(yearly))
        ]
        
        for (title, value) in items {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.alignment = .center
            
            let valueLabel = UILabel()
            valueLabel.text = value
            valueLabel.font = .appTitleMedium
            valueLabel.textColor = .appTextOnLight
            
            let titleLabel = UILabel()
            titleLabel.text = title
            titleLabel.font = .appCaption
            titleLabel.textColor = .secondaryLabel
            
            stack.addArrangedSubview(valueLabel)
            stack.addArrangedSubview(titleLabel)
            
            averagesStack.addArrangedSubview(stack)
        }
    }
    
    private func formatNumber(_ num: Int) -> String {
        NumberFormatter.localizedString(from: NSNumber(value: num), number: .decimal)
    }
    
    private func formatLargeNumber(_ num: Int) -> String {
        if num >= 1_000_000 {
            return String(format: "%.1fM", Double(num) / 1_000_000)
        } else if num >= 1000 {
            return String(format: "%.0fk", Double(num) / 1000)
        }
        return formatNumber(num)
    }
}
