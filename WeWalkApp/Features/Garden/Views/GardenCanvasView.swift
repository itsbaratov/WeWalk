//
//  GardenCanvasView.swift
//  WeWalkApp
//
//  Isometric garden canvas for tree placement
//

import UIKit

final class GardenCanvasView: UIView {
    
    // MARK: - Properties
    
    private var treeViews: [UIImageView] = []
    
    // Ground tiles
    private let rows = 6
    private let cols = 8
    private let tileSize: CGFloat = 100
    
    // MARK: - Init
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGarden()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGarden()
    }
    
    // MARK: - Setup
    
    private func setupGarden() {
        backgroundColor = .clear
        drawGround()
    }
    
    private func drawGround() {
        // Create isometric ground tiles
        for row in 0..<rows {
            for col in 0..<cols {
                let tileView = createGroundTile(row: row, col: col)
                addSubview(tileView)
            }
        }
    }
    
    private func createGroundTile(row: Int, col: Int) -> UIView {
        let tile = UIView()
        
        // Calculate isometric position
        let isoX = (CGFloat(col) - CGFloat(row)) * (tileSize / 2) + bounds.width / 2
        let isoY = (CGFloat(col) + CGFloat(row)) * (tileSize / 4) + 50
        
        tile.frame = CGRect(x: isoX - tileSize/2, y: isoY, width: tileSize, height: tileSize / 2)
        
        // Alternate grass colors
        let isEven = (row + col) % 2 == 0
        tile.backgroundColor = isEven ? UIColor(hex: "#4A7C59") : UIColor(hex: "#5D8A68")
        
        // Diamond shape transform
        tile.layer.cornerRadius = 4
        tile.transform = CGAffineTransform(rotationAngle: .pi / 4).scaledBy(x: 1, y: 0.5)
        
        return tile
    }
    
    // MARK: - Public Methods
    
    func addTree(image: UIImage, at position: CGPoint) {
        let treeView = UIImageView(image: image)
        treeView.contentMode = .scaleAspectFit
        treeView.frame = CGRect(x: position.x - 40, y: position.y - 80, width: 80, height: 80)
        
        // Add slight shadow
        treeView.layer.shadowColor = UIColor.black.cgColor
        treeView.layer.shadowOffset = CGSize(width: 0, height: 4)
        treeView.layer.shadowRadius = 8
        treeView.layer.shadowOpacity = 0.3
        
        addSubview(treeView)
        treeViews.append(treeView)
        
        // Sort by Y position for proper layering
        treeViews.sort { $0.frame.origin.y < $1.frame.origin.y }
        for (index, tree) in treeViews.enumerated() {
            bringSubviewToFront(tree)
        }
    }
    
    func clearTrees() {
        treeViews.forEach { $0.removeFromSuperview() }
        treeViews.removeAll()
    }
}
