//
//  InlinePlantConfirmationView.swift
//  WeWalkApp
//
//  Inline confirmation buttons that appear next to a tree after drop
//

import UIKit

protocol InlinePlantConfirmationDelegate: AnyObject {
    func confirmationViewDidConfirm(_ view: InlinePlantConfirmationView)
    func confirmationViewDidCancel(_ view: InlinePlantConfirmationView)
}

final class InlinePlantConfirmationView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: InlinePlantConfirmationDelegate?
    
    private let shadowContainer: UIView = {
        let view = UIView()
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 8)
        view.layer.shadowRadius = 16
        view.layer.shadowOpacity = 0.15
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let containerView: UIVisualEffectView = {
        let effect = UIBlurEffect(style: .systemUltraThinMaterial)
        let view = UIVisualEffectView(effect: effect)
        view.layer.cornerRadius = 24
        view.clipsToBounds = true
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        button.setImage(UIImage(systemName: "checkmark.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .appStatusSuccess
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        let config = UIImage.SymbolConfiguration(pointSize: 24, weight: .semibold)
        button.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: config), for: .normal)
        button.tintColor = .systemGray
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    // MARK: - Setup
    
    private func setupView() {
        addSubview(shadowContainer)
        shadowContainer.addSubview(containerView)
        
        containerView.contentView.addSubview(stackView)
        
        stackView.addArrangedSubview(cancelButton)
        
        // Add a small divider
        let divider = UIView()
        divider.backgroundColor = UIColor.systemGray.withAlphaComponent(0.3)
        divider.translatesAutoresizingMaskIntoConstraints = false
        stackView.addArrangedSubview(divider)
        
        stackView.addArrangedSubview(confirmButton)
        
        NSLayoutConstraint.activate([
            shadowContainer.topAnchor.constraint(equalTo: topAnchor),
            shadowContainer.leadingAnchor.constraint(equalTo: leadingAnchor),
            shadowContainer.trailingAnchor.constraint(equalTo: trailingAnchor),
            shadowContainer.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            containerView.topAnchor.constraint(equalTo: shadowContainer.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: shadowContainer.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: shadowContainer.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: shadowContainer.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 8),
            stackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -8),
            stackView.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            
            divider.widthAnchor.constraint(equalToConstant: 1),
            divider.heightAnchor.constraint(equalToConstant: 24),
            
            confirmButton.widthAnchor.constraint(equalToConstant: 44),
            confirmButton.heightAnchor.constraint(equalToConstant: 44),
            
            cancelButton.widthAnchor.constraint(equalToConstant: 44),
            cancelButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
        cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        
        // Start hidden
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
    }
    
    // MARK: - Public Methods
    
    func show(animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.alpha = 1
                self.transform = .identity
            }
        } else {
            alpha = 1
            transform = .identity
        }
    }
    
    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { _ in
                completion?()
            }
        } else {
            alpha = 0
            transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            completion?()
        }
    }
    
    // MARK: - Actions
    
    @objc private func confirmTapped() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        delegate?.confirmationViewDidConfirm(self)
    }
    
    @objc private func cancelTapped() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        delegate?.confirmationViewDidCancel(self)
    }
    
    // MARK: - Sizing
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 140, height: 60)
    }
}
