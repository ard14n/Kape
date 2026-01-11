import SwiftUI
import UIKit

/// Service for generating shareable result images using SwiftUI ImageRenderer
/// Architecture: Features/Summary/Logic/ResultImageGenerator.swift
@MainActor
struct ResultImageGenerator {
    
    /// Generates a high-resolution UIImage from the ShareLayoutView
    /// - Parameter result: The GameResult to render
    /// - Returns: UIImage if successful, nil on failure
    static func generate(for result: GameResult) async -> UIImage? {
        let view = ShareLayoutView(result: result)
            .frame(width: 1080, height: 1920)
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0 // High-res for Instagram Stories
        
        return renderer.uiImage
    }
    
    /// Generates an image with custom dimensions
    /// - Parameters:
    ///   - result: The GameResult to render
    ///   - size: Custom size for the image (default 1080x1920)
    /// - Returns: UIImage if successful, nil on failure
    static func generate(for result: GameResult, size: CGSize) async -> UIImage? {
        let view = ShareLayoutView(result: result)
            .frame(width: size.width, height: size.height)
        
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0
        
        return renderer.uiImage
    }
}
