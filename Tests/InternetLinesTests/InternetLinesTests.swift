import XCTest
@testable import InternetLines

final class InternetLinesTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(InternetLines().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
