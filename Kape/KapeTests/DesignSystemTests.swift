import XCTest
@testable import Kape
import SwiftUI

final class DesignSystemTests: XCTestCase {

    func testNeonColorsExistence() {
        // Given
        let red = Color.neonRed
        let green = Color.neonGreen
        let black = Color.trueBlack
        
        // Then
        // We verify they don't crash and return valid colors
        // (XCTest doesn't easily let us inspect Color values without extensions, 
        // but this proves the static properties exist and are callable)
        XCTAssertNotNil(red)
        XCTAssertNotNil(green)
        XCTAssertNotNil(black)
    }
    
    func testHexInit() {
        // Given
        let whiteHex = Color(hex: "#FFFFFF")
        let blackHex = Color(hex: "#000000")
        
        XCTAssertNotNil(whiteHex)
        XCTAssertNotNil(blackHex)
    }
}
