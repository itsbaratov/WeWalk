//
//  MockTreePlantingProvider.swift
//  WeWalkApp
//
//  Mock implementation for development and testing
//

import Foundation

final class MockTreePlantingProvider: TreePlantingProvider {
    
    var providerId: String { "mock_provider" }
    var providerName: String { "Demo Tree Planting" }
    var providerDescription: String { "Mock provider for development and testing" }
    
    // Simulated orders storage
    private var orders: [String: PlantingOrderStatus] = [:]
    
    func createOrder(
        gardenId: UUID,
        treeCount: Int,
        userMetadata: [String: Any]
    ) async throws -> PlantingOrderReference {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let orderId = UUID().uuidString
        
        // Create mock order status
        let status = PlantingOrderStatus(
            orderId: orderId,
            status: .pending,
            message: "Your tree planting order has been received",
            plantedDate: nil,
            region: "Pacific Northwest, USA",
            certificateUrl: nil
        )
        
        orders[orderId] = status
        
        // Create response data for logging
        let responseDict: [String: Any] = [
            "orderId": orderId,
            "treeCount": treeCount,
            "gardenId": gardenId.uuidString,
            "status": "pending"
        ]
        let responseData = try? JSONSerialization.data(withJSONObject: responseDict)
        
        return PlantingOrderReference(
            orderId: orderId,
            provider: providerId,
            createdAt: Date(),
            rawResponse: responseData
        )
    }
    
    func fetchOrderStatus(orderRef: PlantingOrderReference) async throws -> PlantingOrderStatus {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        guard var status = orders[orderRef.orderId] else {
            throw TreePlantingError.orderNotFound
        }
        
        // Simulate status progression
        switch status.status {
        case .pending:
            status = PlantingOrderStatus(
                orderId: status.orderId,
                status: .processing,
                message: "Your trees are being prepared for planting",
                plantedDate: nil,
                region: status.region,
                certificateUrl: nil
            )
        case .processing:
            status = PlantingOrderStatus(
                orderId: status.orderId,
                status: .planted,
                message: "Congratulations! Your trees have been planted!",
                plantedDate: Date(),
                region: status.region,
                certificateUrl: URL(string: "https://example.com/certificate/\(status.orderId)")
            )
        case .planted:
            status = PlantingOrderStatus(
                orderId: status.orderId,
                status: .verified,
                message: "Your tree planting has been verified with photo evidence",
                plantedDate: status.plantedDate,
                region: status.region,
                certificateUrl: status.certificateUrl
            )
        case .verified, .failed:
            // No change
            break
        }
        
        orders[orderRef.orderId] = status
        
        return status
    }
    
    func fetchCertificate(orderRef: PlantingOrderReference) async throws -> URL? {
        let status = try await fetchOrderStatus(orderRef: orderRef)
        return status.certificateUrl
    }
}

// MARK: - Dictionary Encoding Helper

extension Dictionary where Key == String {
    var jsonData: Data? {
        try? JSONSerialization.data(withJSONObject: self)
    }
}
