//
//  ViewModelProtocol.swift
//  WeWalkApp
//
//  Base protocol for all ViewModels
//

import Foundation
import Combine

// MARK: - ViewModel Protocol

protocol ViewModelProtocol: ObservableObject {
    associatedtype Input
    associatedtype Output
    
    func transform(input: Input) -> Output
}

// MARK: - Base ViewModel

class BaseViewModel: ObservableObject {
    var cancellables = Set<AnyCancellable>()
    
    init() {
        setupBindings()
    }
    
    /// Override in subclasses to set up Combine bindings
    func setupBindings() {}
    
    deinit {
        cancellables.removeAll()
    }
}

// MARK: - Loading State

enum LoadingState<T> {
    case idle
    case loading
    case loaded(T)
    case error(Error)
    
    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
    
    var value: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }
    
    var error: Error? {
        if case .error(let error) = self { return error }
        return nil
    }
}
