//
//  WeeklyChartView.swift
//  WeWalkApp
//
//  Horizontal scrolling weekly step chart
//

import UIKit

final class WeeklyChartView: UIView {
    
    // MARK: - UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Last 7 Days Steps"
        label.font = .appTitleSmall
        label.textColor = .appTextOnLight
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
    
    private var barViews: [BarView] = []
    private var maxSteps: Int = 10000
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .appCardBackground
        layer.cornerRadius = AppConstants.Layout.cardCornerRadius
        layer.shadowColor = UIColor.appCardShadow.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 1
        layer.shadowRadius = 12
        
        addSubview(titleLabel)
        addSubview(chartStack)  // Direct add without scroll view
        
        // Update chart stack for 7 bars without scroll
        chartStack.distribution = .fillEqually
        chartStack.spacing = 8
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            // Chart stack fills entire width
            chartStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            chartStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            chartStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            chartStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            chartStack.heightAnchor.constraint(greaterThanOrEqualToConstant: 140)
        ])
    }
    
    // MARK: - Public Methods
    
    func updateChart(with data: [WeeklyStepData.DayStepData]) {
        // Clear existing bars
        chartStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        barViews.removeAll()
        
        guard !data.isEmpty else { return }
        
        // Calculate max steps for scaling
        maxSteps = max(data.map { $0.steps }.max() ?? 10000, 1000)
        
        // Create bars - using fillEqually distribution so no fixed width needed
        for dayData in data {
            let barView = BarView()
            barView.configure(
                steps: dayData.steps,
                label: dayData.dayLabel,
                progress: dayData.goalProgress,
                maxSteps: maxSteps
            )
            
            chartStack.addArrangedSubview(barView)
            barViews.append(barView)
        }
        
        // Animate bars
        animateBars()
    }
    
    private func animateBars() {
        for (index, barView) in barViews.enumerated() {
            barView.animateIn(delay: Double(index) * 0.05)
        }
    }
}

// MARK: - Bar View

private class BarView: UIView {
    
    private let barContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let barView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let stepsLabel: UILabel = {
        let label = UILabel()
        label.font = .appCaptionSmall
        label.textColor = .appSecondaryTextOnLight
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dayLabel: UILabel = {
        let label = UILabel()
        label.font = .appChartLabel
        label.textColor = .appSecondaryTextOnLight
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var barHeightConstraint: NSLayoutConstraint?
    private var targetHeight: CGFloat = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(stepsLabel)
        addSubview(barContainer)
        barContainer.addSubview(barView)
        addSubview(dayLabel)
        
        let heightConstraint = barView.heightAnchor.constraint(equalToConstant: 0)
        heightConstraint.priority = .defaultHigh
        barHeightConstraint = heightConstraint
        
        NSLayoutConstraint.activate([
            stepsLabel.topAnchor.constraint(equalTo: topAnchor),
            stepsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            barContainer.topAnchor.constraint(equalTo: stepsLabel.bottomAnchor, constant: 4),
            barContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            barContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            barContainer.bottomAnchor.constraint(equalTo: dayLabel.topAnchor, constant: -4),
            
            barView.leadingAnchor.constraint(equalTo: barContainer.leadingAnchor, constant: 1),
            barView.trailingAnchor.constraint(equalTo: barContainer.trailingAnchor, constant: -1),
            barView.bottomAnchor.constraint(equalTo: barContainer.bottomAnchor),
            heightConstraint,
            
            dayLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            dayLabel.centerXAnchor.constraint(equalTo: centerXAnchor)
        ])
    }
    
    func configure(steps: Int, label: String, progress: Double, maxSteps: Int) {
        stepsLabel.text = formatSteps(steps)
        dayLabel.text = label
        
        // Color based on goal progress
        if progress >= 1.0 {
            barView.backgroundColor = .appStatusSuccess
        } else if progress >= 0.5 {
            barView.backgroundColor = .appStatusWarning
        } else {
            barView.backgroundColor = .appStatusRisk
        }
        
        // Calculate bar height (max 80 points)
        let heightRatio = CGFloat(steps) / CGFloat(maxSteps)
        targetHeight = max(4, heightRatio * 80)
    }
    
    func animateIn(delay: Double) {
        barHeightConstraint?.constant = 0
        layoutIfNeeded()
        
        UIView.animate(
            withDuration: 0.5,
            delay: delay,
            usingSpringWithDamping: 0.7,
            initialSpringVelocity: 0.5,
            options: [],
            animations: {
                self.barHeightConstraint?.constant = self.targetHeight
                self.layoutIfNeeded()
            }
        )
    }
    
    private func formatSteps(_ steps: Int) -> String {
        if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000)
        }
        return "\(steps)"
    }
}
