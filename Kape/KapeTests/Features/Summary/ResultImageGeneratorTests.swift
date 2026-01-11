import XCTest
@testable import Kape

/// Unit tests for ResultImageGenerator
/// Architecture: KapeTests/Features/Summary/ResultImageGeneratorTests.swift
/// Test IDs: 3.3-UNIT-001 through 3.3-UNIT-008 (TEA Recommendation)
@MainActor
final class ResultImageGeneratorTests: XCTestCase {
    
    // MARK: - AC 3: Image Generation Tests
    
    /// [3.3-UNIT-001] Generates image for valid result
    func testGenerate_WithValidResult_ReturnsNonNilImage() async {
        // Given
        let result = GameResultFactory.make()
        
        // When
        let image = await ResultImageGenerator.generate(for: result)
        
        // Then
        XCTAssertNotNil(image, "Image should not be nil for valid GameResult")
    }
    
    /// [3.3-UNIT-002] Generates image for Legjendë rank
    func testGenerate_ForLegjende_ReturnsImage() async {
        // Given: Score 10+ = Legjendë
        let result = GameResultFactory.make(forRank: .legjende)
        XCTAssertEqual(result.rank, .legjende)
        
        // When
        let image = await ResultImageGenerator.generate(for: result)
        
        // Then
        XCTAssertNotNil(image, "Image should not be nil for Legjendë rank")
    }
    
    /// [3.3-UNIT-003] Generates image for Shqipe rank
    func testGenerate_ForShqipe_ReturnsImage() async {
        // Given: Score 5-9 = Shqipe
        let result = GameResultFactory.make(forRank: .shqipe)
        XCTAssertEqual(result.rank, .shqipe)
        
        // When
        let image = await ResultImageGenerator.generate(for: result)
        
        // Then
        XCTAssertNotNil(image, "Image should not be nil for Shqipe rank")
    }
    
    /// [3.3-UNIT-004] Generates image for Mish i Huaj rank
    func testGenerate_ForMishIHuaj_ReturnsImage() async {
        // Given: Score 0-4 = Mish i Huaj
        let result = GameResultFactory.make(forRank: .mishIHuaj)
        XCTAssertEqual(result.rank, .mishIHuaj)
        
        // When
        let image = await ResultImageGenerator.generate(for: result)
        
        // Then
        XCTAssertNotNil(image, "Image should not be nil for Mish i Huaj rank")
    }
    
    /// [3.3-UNIT-005] Generates images for all rank boundary scores
    func testGenerate_ForAllRankBoundaries_ReturnsImages() async {
        // Given: Boundary scores for each rank
        let testCases: [(score: Int, expectedRank: Rank)] = [
            (0, .mishIHuaj),   // Minimum
            (4, .mishIHuaj),   // Boundary upper
            (5, .shqipe),      // Boundary lower
            (9, .shqipe),      // Boundary upper
            (10, .legjende),   // Boundary lower
            (15, .legjende)    // High score
        ]
        
        for (score, expectedRank) in testCases {
            let result = GameResultFactory.make(score: score, passed: 0)
            
            // Verify rank assignment
            XCTAssertEqual(result.rank, expectedRank, "Score \(score) should be \(expectedRank)")
            
            // When
            let image = await ResultImageGenerator.generate(for: result)
            
            // Then
            XCTAssertNotNil(image, "Image should not be nil for score \(score) / rank \(expectedRank)")
        }
    }
    
    /// [3.3-UNIT-006] Generates image with custom dimensions
    func testGenerate_WithCustomSize_ReturnsImage() async {
        // Given
        let result = GameResultFactory.make(score: 8, passed: 2)
        let customSize = CGSize(width: 540, height: 960) // Half size
        
        // When
        let image = await ResultImageGenerator.generate(for: result, size: customSize)
        
        // Then
        XCTAssertNotNil(image, "Image should not be nil with custom size")
        
        // Verify dimensions (UIImage.size returns points)
        if let image = image {
            XCTAssertEqual(image.size.width, customSize.width, accuracy: 1.0, "Width should be \(customSize.width) points")
            XCTAssertEqual(image.size.height, customSize.height, accuracy: 1.0, "Height should be \(customSize.height) points")
        }
    }
    
    /// [3.3-UNIT-007] Validates standard image dimensions and scale
    func testGenerate_ImageHasCorrectDimensionsAndScale() async {
        // Given
        let result = GameResultFactory.make()
        
        // When
        let image = await ResultImageGenerator.generate(for: result)
        
        // Then
        XCTAssertNotNil(image)
        if let image = image {
            // UIImage.size returns points (1080x1920)
            XCTAssertEqual(image.size.width, 1080, accuracy: 1.0, "Image width should be 1080 points")
            XCTAssertEqual(image.size.height, 1920, accuracy: 1.0, "Image height should be 1920 points")
            
            // Verify scale is applied correctly (3.0 for high-res)
            XCTAssertEqual(image.scale, 3.0, accuracy: 0.1, "Image scale should be 3.0")
        }
    }
    
    /// [3.3-UNIT-008] Validates 9:16 portrait aspect ratio for Instagram Stories
    func testGenerate_ImageHasCorrectAspectRatio() async {
        // Given: 9:16 aspect ratio for Instagram Stories
        let result = GameResultFactory.make(score: 5, passed: 5)
        
        // When
        let image = await ResultImageGenerator.generate(for: result)
        
        // Then
        XCTAssertNotNil(image)
        if let image = image {
            let aspectRatio = image.size.height / image.size.width
            let expectedRatio: CGFloat = 1920.0 / 1080.0 // 16:9 portrait = ~1.778
            XCTAssertEqual(aspectRatio, expectedRatio, accuracy: 0.01, "Aspect ratio should be 16:9 portrait")
        }
    }
}
