//
//  TreePlantingProvider.swift
//  WeWalkApp
//
//  Protocol for real tree planting API providers
//

import Foundation

// MARK: - Order Types

struct PlantingOrderReference: Codable {
    let orderId: String
    let provider: String
    let createdAt: Date
    let rawResponse: Data?  // Store provider's raw response for debugging
}

enum PlantingStatus: String, Codable {
    case pending
    case processing
    case planted
    case verified
    case failed
    
    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .processing: return "Processing"
        case .planted: return "Planted"
        case .verified: return "Verified"
        case .failed: return "Failed"
        }
    }
    
    var isComplete: Bool {
        self == .planted || self == .verified
    }
}

struct PlantingOrderStatus: Codable {
    let orderId: String
    let status: PlantingStatus
    let message: String?
    let plantedDate: Date?
    let region: String?
    let certificateUrl: URL?
}

// MARK: - Provider Protocol

protocol TreePlantingProvider {
    var providerId: String { get }
    var providerName: String { get }
    var providerDescription: String { get }
    
    /// Create a new tree planting order
    func createOrder(
        gardenId: UUID,
        treeCount: Int,
        userMetadata: [String: Any]
    ) async throws -> PlantingOrderReference
    
    /// Fetch the status of an existing order
    func fetchOrderStatus(orderRef: PlantingOrderReference) async throws -> PlantingOrderStatus
    
    /// Fetch certificate URL for a completed order
    func fetchCertificate(orderRef: PlantingOrderReference) async throws -> URL?
}

// MARK: - Provider Errors

enum TreePlantingError: Error, LocalizedError {
    case notConfigured
    case networkError(Error)
    case invalidResponse
    case orderNotFound
    case insufficientCredits
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Tree planting provider is not configured"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from tree planting provider"
        case .orderNotFound:
            return "Order not found"
        case .insufficientCredits:
            return "Insufficient credits for tree planting"
        }
    }
}

// MARK: - Provider Registry

final class TreePlantingProviderRegistry {
    static let shared = TreePlantingProviderRegistry()
    
    private var providers: [String: TreePlantingProvider] = [:]
    private(set) var activeProvider: TreePlantingProvider?
    
    private init() {
        // Register mock provider by default
        let mockProvider = MockTreePlantingProvider()
        registerProvider(mockProvider)
        setActiveProvider(id: mockProvider.providerId)
    }
    
    func registerProvider(_ provider: TreePlantingProvider) {
        providers[provider.providerId] = provider
    }
    
    func setActiveProvider(id: String) {
        activeProvider = providers[id]
    }
    
    func provider(byId id: String) -> TreePlantingProvider? {
        providers[id]
    }
    
    var availableProviders: [TreePlantingProvider] {
        Array(providers.values)
    }
}

