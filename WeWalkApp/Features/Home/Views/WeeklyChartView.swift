//
//  WeeklyChartView.swift
//  WeWalkApp
//
//  Horizontal scrolling step chart with dynamic scaling and smooth animations
//

import UIKit

final class WeeklyChartView: UIView {
    
    // MARK: - UI Elements
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Step History"
        label.font = .appTitleSmall
        label.textColor = .appTextOnLight
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = false
        scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false
        scroll.delegate = self
        // Clip to bounds to prevent overflow outside the card
        scroll.clipsToBounds = true
        return scroll
    }()
    
    private let chartStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 1
        stack.alignment = .bottom // Align to bottom so bars grow up
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var barViews: [BarView] = []
    
    // Layout Constants
    private let visibleBarCount: CGFloat = 7
    private let barSpacing: CGFloat = 1
    private var barWidth: CGFloat = 0
    private var currentMaxHeight: CGFloat = 100 // Dynamic
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Recalculate if frame changes
        if frame.width > 0 {
             configureLayoutMetrics()
        }
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .appCardBackground
        layer.cornerRadius = AppConstants.Layout.cardCornerRadius
        layer.shadowColor = UIColor.appCardShadow.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 4)
        layer.shadowOpacity = 1
        layer.shadowRadius = 12
        // Ensure the Main Card clips subviews so scrolling content doesn't bleed out
        clipsToBounds = true 
        
        addSubview(titleLabel)
        addSubview(scrollView)
        scrollView.addSubview(chartStack)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            
            // Scrollview takes remaining space
            // Reduce top constant to allow bars to reach higher up near the title
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            // Ensure padding from edges so bars don't touch screen edge
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16),
            
            // Stack fills scrollview content
            chartStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            chartStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            chartStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            chartStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            chartStack.heightAnchor.constraint(equalTo: scrollView.heightAnchor)
        ])
    }
    
    private func configureLayoutMetrics() {
        let availableWidth = scrollView.bounds.width
        let totalSpacing = (visibleBarCount - 1) * barSpacing
        barWidth = (availableWidth - totalSpacing) / visibleBarCount
        
        // Calculate dynamic max available height for the bars
        // Total scroll height - (Day Label Height ~20 + Steps Label padding ~15)
        // We want the bar to be able to grow almost to the top of the scroll view
        let totalHeight = scrollView.bounds.height
        currentMaxHeight = max(40, totalHeight - 40)
        
        // Update any existing bars
        barViews.forEach { bar in
            bar.widthConstraint?.constant = barWidth
            bar.maxAvailableHeight = currentMaxHeight
        }
        
        // Trigger generic update
        updateVisibleBarsScaling()
    }
    
    // MARK: - Public Methods
    
    func updateChart(with data: [WeeklyStepData.DayStepData]) {
        // Clear existing bars
        chartStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        barViews.removeAll()
        
        guard !data.isEmpty else { return }
        
        // Calculate layout if needed
        if barWidth == 0 {
             configureLayoutMetrics()
        }
        
        let today = Date()
        let calendar = Calendar.current
        
        // Create bars
        for dayData in data {
            let barView = BarView()
            
            // Determine label format
            let daysAgo = calendar.dateComponents([.day], from: dayData.date.startOfDay, to: today.startOfDay).day ?? 0
            let useWeekdayLabel = daysAgo <= 6 && daysAgo >= 0
            let label = useWeekdayLabel ? dayData.dayLabel : dayData.dateLabel
            
            barView.configure(
                steps: dayData.steps,
                label: label,
                progress: dayData.goalProgress
            )
            
            // Set dynamic width
            barView.translatesAutoresizingMaskIntoConstraints = false
            let widthConstraint = barView.widthAnchor.constraint(equalToConstant: barWidth)
            widthConstraint.isActive = true
            barView.widthConstraint = widthConstraint
            barView.maxAvailableHeight = currentMaxHeight
            
            chartStack.addArrangedSubview(barView)
            barViews.append(barView)
        }
        
        // Force layout
        layoutIfNeeded()
        updateVisibleBarsScaling() // Initial scaling
        
        // Scroll to end (most recent)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            guard let self = self else { return }
            let contentWidth = self.scrollView.contentSize.width
            let scrollViewWidth = self.scrollView.bounds.width
            if contentWidth > scrollViewWidth {
                let offsetX = contentWidth - scrollViewWidth
                self.scrollView.setContentOffset(CGPoint(x: offsetX, y: 0), animated: false)
            }
        }
    }
    
    // MARK: - Scaling Logic
    
    private func updateVisibleBarsScaling() {
        guard !barViews.isEmpty else { return }
        
        // 1. Identify visible bars
        let visibleRect = CGRect(origin: scrollView.contentOffset, size: scrollView.bounds.size)
        // Add small buffer
        let extendedRect = visibleRect.insetBy(dx: -barWidth, dy: 0)
        
        var visibleBars: [BarView] = []
        
        for bar in barViews {
            let barFrame = bar.convert(bar.bounds, to: scrollView)
            if extendedRect.intersects(barFrame) {
                visibleBars.append(bar)
            }
        }
        
        guard !visibleBars.isEmpty else { return }
        
        // 2. Find max steps in visible range
        let visibleMaxSteps = visibleBars.map { $0.steps }.max() ?? 1
        let maxSteps = max(visibleMaxSteps, 1000) 
        
        // 3. Update heights proportionally to LOCAL max with animation
        UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseOut, .beginFromCurrentState], animations: {
            for bar in visibleBars {
                let heightRatio = CGFloat(bar.steps) / CGFloat(maxSteps)
                // Use currentMaxHeight which fills available vertical space
                let targetHeight = max(4, heightRatio * self.currentMaxHeight)
                bar.updateHeight(targetHeight)
            }
            self.layoutIfNeeded() 
        }, completion: nil)
    }
}

// MARK: - Scroll Delegate

extension WeeklyChartView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateVisibleBarsScaling()
    }
}

// MARK: - Bar View

private class BarView: UIView {
    
    var steps: Int = 0
    var widthConstraint: NSLayoutConstraint?
    var maxAvailableHeight: CGFloat = 80
    
    private let stepsLabel: UILabel = {
        let label = UILabel()
        label.font = .appChartLabel
        label.textAlignment = .center
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.isHidden = false
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let barContainer: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let barDisplayView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(barContainer)
        addSubview(dayLabel)
        
        // NO STACK, just steps label directly
        addSubview(stepsLabel)
        
        barContainer.addSubview(barDisplayView)
        
        let heightConstraint = barDisplayView.heightAnchor.constraint(equalToConstant: 0)
        barHeightConstraint = heightConstraint
        
        NSLayoutConstraint.activate([
            // Day Label at bottom
            dayLabel.bottomAnchor.constraint(equalTo: bottomAnchor),
            dayLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            dayLabel.heightAnchor.constraint(equalToConstant: 20),
            
            // Bar Container occupies space above day label
            barContainer.topAnchor.constraint(equalTo: topAnchor),
            barContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            barContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            barContainer.bottomAnchor.constraint(equalTo: dayLabel.topAnchor, constant: -4),
            
            // Bar Display View - anchored to BOTTOM of container
            barDisplayView.bottomAnchor.constraint(equalTo: barContainer.bottomAnchor),
            barDisplayView.leadingAnchor.constraint(equalTo: barContainer.leadingAnchor, constant: 4),
            barDisplayView.trailingAnchor.constraint(equalTo: barContainer.trailingAnchor, constant: -4),
            heightConstraint,
            
            // Steps Label - Anchored to TOP of the Bar Display View
            stepsLabel.bottomAnchor.constraint(equalTo: barDisplayView.topAnchor, constant: -2),
            stepsLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            stepsLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor)
        ])
    }
    
    func configure(steps: Int, label: String, progress: Double) {
        self.steps = steps
        stepsLabel.text = "\(steps)"
        dayLabel.text = label
        
        // Color logic
        let color: UIColor
        if progress >= 1.0 {
            color = .appStatusSuccess
        } else if progress >= 0.5 {
            color = .appStatusWarning
        } else {
            color = .appStatusRisk
        }
        
        barDisplayView.backgroundColor = color
        stepsLabel.textColor = color
    }
    
    func updateHeight(_ height: CGFloat) {
        // Ensure height doesn't exceed visual bounds
        let safeHeight = min(height, maxAvailableHeight)
        if barHeightConstraint?.constant != safeHeight {
            barHeightConstraint?.constant = safeHeight
        }
    }
}
