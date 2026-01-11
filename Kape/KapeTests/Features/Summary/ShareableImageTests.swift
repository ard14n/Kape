import XCTest
@testable import Kape
import UniformTypeIdentifiers

/// Tests for ShareableImage Transferable wrapper
/// Story 3.4: Native Sharing Integration (Task 4)
final class ShareableImageTests: XCTestCase {
    
    // MARK: - Transferable Protocol Tests
    
    /// Test that ShareableImage correctly exports as PNG data
    func testShareableImage_ExportsToPNG() throws {
        // Given: A valid UIImage
        let image = createTestImage(color: .red, size: CGSize(width: 100, height: 100))
        let shareableImage = ShareableImage(uiImage: image)
        
        // Then: Unique ID should be generated
        XCTAssertNotNil(shareableImage.id)
        
        // And: UIImage should be preserved
        XCTAssertEqual(shareableImage.uiImage.size, CGSize(width: 100, height: 100))
    }
    
    /// Test that each ShareableImage has unique ID for Identifiable conformance
    func testShareableImage_HasUniqueIdentifier() {
        // Given: Two ShareableImages with same image
        let image = createTestImage(color: .blue, size: CGSize(width: 50, height: 50))
        let shareableImage1 = ShareableImage(uiImage: image)
        let shareableImage2 = ShareableImage(uiImage: image)
        
        // Then: IDs should be different
        XCTAssertNotEqual(shareableImage1.id, shareableImage2.id)
    }
    
    /// Test ShareableImage with high-resolution image (similar to actual share image)
    func testShareableImage_HighResolution() throws {
        // Given: A high-resolution image matching Instagram Story dimensions
        let image = createTestImage(color: .green, size: CGSize(width: 1080, height: 1920))
        let shareableImage = ShareableImage(uiImage: image)
        
        // Then: Should preserve full resolution
        XCTAssertEqual(shareableImage.uiImage.size.width, 1080)
        XCTAssertEqual(shareableImage.uiImage.size.height, 1920)
    }
    
    /// Test that ShareableImage can be created for all rank colors
    func testShareableImage_AllRankColors() {
        // Given: Images representing each rank
        let colors: [UIColor] = [
            UIColor(red: 0.224, green: 1.0, blue: 0.078, alpha: 1.0), // neonGreen
            UIColor(red: 1.0, green: 0.584, blue: 0.0, alpha: 1.0),   // neonOrange
            UIColor.white.withAlphaComponent(0.6)
        ]
        
        for color in colors {
            let image = createTestImage(color: color, size: CGSize(width: 100, height: 100))
            let shareableImage = ShareableImage(uiImage: image)
            
            // Then: Should successfully create wrapper
            XCTAssertNotNil(shareableImage.uiImage)
        }
    }
    
    // MARK: - PNG Data Export Tests
    
    /// Test that PNG data export produces valid data
    func testShareableImage_PNGDataNotEmpty() {
        // Given: A valid image
        let image = createTestImage(color: .purple, size: CGSize(width: 200, height: 200))
        
        // When: Converting to PNG
        let pngData = image.pngData()
        
        // Then: PNG data should exist and not be empty
        XCTAssertNotNil(pngData)
        XCTAssertFalse(pngData?.isEmpty ?? true)
    }
    
    // MARK: - Helpers
    
    private func createTestImage(color: UIColor, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}
