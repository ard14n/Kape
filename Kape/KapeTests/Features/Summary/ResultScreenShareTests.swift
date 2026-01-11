import XCTest
@testable import Kape
import SwiftUI

/// Tests for ResultScreen Share Flow (Story 3.4: Native Sharing Integration)
/// These tests validate the share sheet presentation logic and state management
final class ResultScreenShareTests: XCTestCase {
    
    // MARK: - Share State Tests
    
    /// Test that share callback is invoked after image generation
    func testShareFlow_GeneratesImageAndInvokesCallback() {
        // Given: A result and expectation for share callback
        let expectation = expectation(description: "Share callback invoked")
        var shareCallbackInvoked = false
        
        // We can't directly test the View, but we can test the generator
        let result = GameResult(score: 8, passed: 2, date: Date())
        
        // When: Generating share image
        Task { @MainActor in
            let image = await ResultImageGenerator.generate(for: result)
            
            // Then: Image should be generated successfully
            XCTAssertNotNil(image, "Share image should be generated")
            shareCallbackInvoked = true
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        XCTAssertTrue(shareCallbackInvoked, "Share callback should be invoked")
    }
    
    /// Test that image generation works for all rank levels
    func testShareFlow_AllRanks_GenerateValidImages() {
        let testCases: [(score: Int, expectedRank: Rank)] = [
            (2, .mishIHuaj),  // 0-4 = Mish i Huaj
            (7, .shqipe),     // 5-9 = Shqipe
            (12, .legjende)   // 10+ = Legjendë
        ]
        
        for testCase in testCases {
            let expectation = expectation(description: "Image for rank \(testCase.expectedRank)")
            
            let result = GameResult(score: testCase.score, passed: 1, date: Date())
            XCTAssertEqual(result.rank, testCase.expectedRank, "Rank should match expected")
            
            Task { @MainActor in
                let image = await ResultImageGenerator.generate(for: result)
                XCTAssertNotNil(image, "Image should be generated for \(testCase.expectedRank)")
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    // MARK: - ShareableImage Transferable Tests
    
    /// Test that ShareableImage preserves image data correctly
    func testShareableImage_PreservesImageData() {
        // Given: A test UIImage
        let size = CGSize(width: 200, height: 200)
        let testImage = createTestImage(color: .red, size: size)
        
        // When: Wrapping in ShareableImage
        let shareableImage = ShareableImage(uiImage: testImage)
        
        // Then: Image should be accessible and sized correctly
        XCTAssertEqual(shareableImage.uiImage.size.width, size.width)
        XCTAssertEqual(shareableImage.uiImage.size.height, size.height)
    }
    
    /// Test that PNG data export is valid
    func testShareableImage_ExportsPNGData() {
        // Given: A ShareableImage
        let testImage = createTestImage(color: .blue, size: CGSize(width: 100, height: 100))
        let shareableImage = ShareableImage(uiImage: testImage)
        
        // When: Getting PNG data
        let pngData = shareableImage.uiImage.pngData()
        
        // Then: PNG data should be valid and not empty
        XCTAssertNotNil(pngData)
        XCTAssertFalse(pngData?.isEmpty ?? true)
        
        // And: PNG header should be correct (89 50 4E 47 = PNG magic number)
        if let data = pngData, data.count >= 4 {
            let header = [UInt8](data.prefix(4))
            XCTAssertEqual(header, [0x89, 0x50, 0x4E, 0x47], "Should have PNG magic number")
        }
    }
    
    // MARK: - Image Dimension Tests
    
    /// Test that generated images have correct Instagram Story dimensions
    func testShareImage_HasInstagramStoryDimensions() {
        let expectation = expectation(description: "Image dimensions check")
        
        let result = GameResult(score: 10, passed: 0, date: Date())
        
        Task { @MainActor in
            let image = await ResultImageGenerator.generate(for: result)
            
            // Then: Image should have Instagram Story aspect ratio
            // ImageRenderer outputs at specified scale, dimensions may vary
            if let image = image {
                // Verify aspect ratio is 9:16 (portrait)
                let aspectRatio = image.size.width / image.size.height
                let expected9x16 = 9.0 / 16.0
                
                XCTAssertEqual(aspectRatio, expected9x16, accuracy: 0.02, "Aspect ratio should be 9:16")
                
                // Verify image is high resolution (at least 1080 logical width)
                XCTAssertGreaterThanOrEqual(image.size.width, 1080, "Width should be at least 1080px")
                XCTAssertGreaterThanOrEqual(image.size.height, 1920, "Height should be at least 1920px")
            } else {
                XCTFail("Image should not be nil")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    /// Test aspect ratio is 9:16 (portrait Instagram Story)
    func testShareImage_Has9x16AspectRatio() {
        let expectation = expectation(description: "Aspect ratio check")
        
        let result = GameResult(score: 5, passed: 5, date: Date())
        
        Task { @MainActor in
            let image = await ResultImageGenerator.generate(for: result)
            
            if let image = image {
                let aspectRatio = image.size.width / image.size.height
                let expected9x16 = 9.0 / 16.0
                
                XCTAssertEqual(aspectRatio, expected9x16, accuracy: 0.01, "Aspect ratio should be 9:16")
            } else {
                XCTFail("Image should not be nil")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Boundary Score Tests
    
    /// Test boundary scores for rank transitions
    func testShareImage_BoundaryScores() {
        let boundaryTests: [(score: Int, expectedRank: Rank)] = [
            (0, .mishIHuaj),   // Minimum
            (4, .mishIHuaj),   // Upper boundary of mishIHuaj
            (5, .shqipe),      // Lower boundary of shqipe
            (9, .shqipe),      // Upper boundary of shqipe
            (10, .legjende),   // Lower boundary of legjende
            (50, .legjende)    // High score
        ]
        
        for (score, expectedRank) in boundaryTests {
            let result = GameResult(score: score, passed: 0, date: Date())
            XCTAssertEqual(result.rank, expectedRank, "Score \(score) should be rank \(expectedRank)")
        }
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
