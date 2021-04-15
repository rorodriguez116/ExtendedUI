import XCTest
@testable import ExtendedUI

final class ExtendedUITests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(ExtendedUI().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
