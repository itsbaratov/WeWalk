//
//  StatsCardView.swift
//  WeWalkApp
//
//  Card view for displaying distance and calories with circular icon backgrounds
//

import UIKit

final class StatsCardView: UIView {

    // MARK: - UI Elements

    private var distanceValueLabel: UILabel!
    private var caloriesValueLabel: UILabel!

    private let distanceContainer = UIView()
    private let caloriesContainer = UIView()

    private let dividerView: UIView = {
        let v = UIView()
        v.backgroundColor = .appDivider
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    // MARK: - Layout Constants

    private let contentInset: CGFloat = 16          // card inner padding
    private let sectionToDividerSpacing: CGFloat = 16 // must equal contentInset per your requirement
    private let dividerWidth: CGFloat = 1
    private let dividerVerticalInset: CGFloat = 8

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

        distanceContainer.translatesAutoresizingMaskIntoConstraints = false
        caloriesContainer.translatesAutoresizingMaskIntoConstraints = false

        addSubview(distanceContainer)
        addSubview(dividerView)
        addSubview(caloriesContainer)

        // Build sections
        let distance = buildStatContent(
            in: distanceContainer,
            icon: "location.fill",
            title: "Distance",
            value: "0 m",
            iconColor: .appMintGreen
        )

        let calories = buildStatContent(
            in: caloriesContainer,
            icon: "flame.fill",
            title: "Calories",
            value: "0 kcal",
            iconColor: .appMintGreen
        )

        distanceValueLabel = distance
        caloriesValueLabel = calories

        // Divider: centered horizontally inside the card
        NSLayoutConstraint.activate([
            dividerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            dividerView.widthAnchor.constraint(equalToConstant: dividerWidth),
            dividerView.topAnchor.constraint(equalTo: topAnchor, constant: contentInset + dividerVerticalInset),
            dividerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -(contentInset + dividerVerticalInset))
        ])

        // Distance / Calories containers with equal insets/offsets around divider and card edges
        NSLayoutConstraint.activate([
            // Distance section
            distanceContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: contentInset),
            distanceContainer.trailingAnchor.constraint(equalTo: dividerView.leadingAnchor, constant: -sectionToDividerSpacing),
            distanceContainer.topAnchor.constraint(equalTo: topAnchor, constant: contentInset),
            distanceContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInset),

            // Calories section
            caloriesContainer.leadingAnchor.constraint(equalTo: dividerView.trailingAnchor, constant: sectionToDividerSpacing),
            caloriesContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -contentInset),
            caloriesContainer.topAnchor.constraint(equalTo: topAnchor, constant: contentInset),
            caloriesContainer.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -contentInset),

            // Ensure both sections have equal width (symmetry)
            distanceContainer.widthAnchor.constraint(equalTo: caloriesContainer.widthAnchor)
        ])
    }

    /// Builds one stat section inside a container and returns the value label reference.
    private func buildStatContent(
        in container: UIView,
        icon: String,
        title: String,
        value: String,
        iconColor: UIColor
    ) -> UILabel {

        // Circular icon background
        let iconBackground = UIView()
        iconBackground.backgroundColor = iconColor.withAlphaComponent(0.15)
        iconBackground.layer.cornerRadius = 22
        iconBackground.translatesAutoresizingMaskIntoConstraints = false

        let iconView = UIImageView()
        iconView.image = UIImage(systemName: icon)
        iconView.tintColor = iconColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false

        // Text stack
        let textStack = UIStackView()
        textStack.axis = .vertical
        textStack.spacing = 2
        textStack.alignment = .leading
        textStack.distribution = .fill
        textStack.translatesAutoresizingMaskIntoConstraints = false

        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = .appLabelBold
        titleLabel.textColor = .appSecondaryTextOnLight
        titleLabel.numberOfLines = 1
        titleLabel.lineBreakMode = .byClipping

        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = .appTitleMedium
        valueLabel.textColor = .appTextOnLight
        valueLabel.numberOfLines = 1
        valueLabel.lineBreakMode = .byClipping

        // Prefer shrinking over truncation
        valueLabel.adjustsFontSizeToFitWidth = true
        valueLabel.minimumScaleFactor = 0.65

        // Make labels more willing to compress horizontally (so they shrink instead of forcing ellipses)
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        valueLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        valueLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        textStack.addArrangedSubview(titleLabel)
        textStack.addArrangedSubview(valueLabel)

        container.addSubview(iconBackground)
        iconBackground.addSubview(iconView)
        container.addSubview(textStack)

        NSLayoutConstraint.activate([
            iconBackground.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconBackground.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconBackground.widthAnchor.constraint(equalToConstant: 44),
            iconBackground.heightAnchor.constraint(equalToConstant: 44),

            iconView.centerXAnchor.constraint(equalTo: iconBackground.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconBackground.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 24),
            iconView.heightAnchor.constraint(equalToConstant: 24),

            textStack.leadingAnchor.constraint(equalTo: iconBackground.trailingAnchor, constant: 10),
            textStack.centerYAnchor.constraint(equalTo: container.centerYAnchor),

            // This is key: give the text a real trailing constraint so it can measure and shrink properly.
            textStack.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])

        return valueLabel
    }

    // MARK: - Public Methods

    func updateStats(distance: String, calories: String) {
        distanceValueLabel.text = distance
        caloriesValueLabel.text = calories
    }
}
