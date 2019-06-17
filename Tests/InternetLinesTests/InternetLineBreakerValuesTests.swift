//
//  InternetLineBreakerValuesTests.swift
//  InternetLinesTests
//
//  Created by Daryle Walker on 6/15/19.
//

import XCTest
@testable import InternetLines


class InternetLineBreakerValuesTests: XCTestCase {

    // Test the CR and LF values for the standard conforming types
    func testInternetLineBreakConstants() {
        XCTAssertEqual(UnicodeScalar.crValue, "\r")
        XCTAssertEqual(UnicodeScalar.lfValue, "\n")

        XCTAssertEqual(Int.crValue, 13)
        XCTAssertEqual(Int.lfValue, 10)
        XCTAssertEqual(UInt.crValue, 13)
        XCTAssertEqual(UInt.lfValue, 10)

        XCTAssertEqual(Int8.crValue, 13)
        XCTAssertEqual(Int8.lfValue, 10)
        XCTAssertEqual(UInt8.crValue, 13)
        XCTAssertEqual(UInt8.lfValue, 10)
        XCTAssertEqual(UInt16.crValue, 13)
        XCTAssertEqual(UInt16.lfValue, 10)
        XCTAssertEqual(UInt32.crValue, 13)
        XCTAssertEqual(UInt32.lfValue, 10)

        XCTAssertEqual(UnicodeScalar.crValue.value, UInt32.crValue)
        XCTAssertEqual(UnicodeScalar.lfValue.value, UInt32.lfValue)
    }

    static var allTests = [
        ("testInternetLineBreakConstants", testInternetLineBreakConstants),
    ]

}
