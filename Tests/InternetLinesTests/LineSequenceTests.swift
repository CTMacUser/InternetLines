//
//  LineSequenceTests.swift
//  InternetLinesTests
//
//  Created by Daryle Walker on 7/28/19.
//

import XCTest
@testable import InternetLines


class LineSequenceTests: XCTestCase {

    // Convert a collection pair to a 2-element array.
    static func convert<T>(_ x: (data: T, terminator: T)) -> [T] {
        return [x.data, x.terminator]
    }

    // Test empty sequences
    func testEmpty() {
        let emptyChar = [UnicodeScalar]().parsedLines(considering: .strict)
        XCTAssertEqual(emptyChar.underestimatedCount, 0)
        XCTAssertTrue(Array(emptyChar).isEmpty)

        let emptyInt = [UInt32]().parsedLines(considering: .strict)
        XCTAssertEqual(emptyInt.underestimatedCount, 0)
        XCTAssertTrue(Array(emptyInt).isEmpty)
    }

    // Test unterminated line
    func testUnterminated() {
        //            012345678901234567890123456789
        let sample = "There are no line breaks here."
        let sampleC = Array(sample.unicodeScalars)
        let sampleCLines = sampleC.parsedLines(considering: .strict)
        XCTAssertEqual(sampleCLines.underestimatedCount, 1)
        XCTAssertEqual(Array(sampleCLines).map(LineSequenceTests.convert), [[sampleC, [UnicodeScalar]()]])

        let sampleI = sampleC.map { $0.value }
        let sampleILines = sampleI.parsedLines(considering: .strict)
        XCTAssertEqual(sampleILines.underestimatedCount, 1)
        XCTAssertEqual(Array(sampleILines).map(LineSequenceTests.convert), [[sampleI, [UInt32]()]])
    }

    // Test all sorts of lines
    func testAllTerminators() {
        //            012345678 9012345678 901234567890 1 234567890 1 2 3456
        let sample = "The quick\rbrown fox\njumped over\r\nthe lazy\r\r\ndog"
        let sampleLines = [
            ["The quick", "\r"],
            ["brown fox", "\n"],
            ["jumped over", "\r\n"],
            ["the lazy", "\r\r\n"],
            ["dog", ""]
        ]
        let sampleC = Array(sample.unicodeScalars)
        var sampleCLines = sampleC.parsedLines(considering: .all)
        XCTAssertEqual(sampleCLines.underestimatedCount, 1)
        XCTAssertEqual(Array(sampleCLines).map(LineSequenceTests.convert), sampleLines.map { $0.map { Array($0.unicodeScalars) } })
        sampleCLines = sampleC.parsedLines(considering: .paranoid)
        XCTAssertEqual(sampleCLines.underestimatedCount, 1)
        XCTAssertEqual(Array(sampleCLines).map(LineSequenceTests.convert), sampleLines.map { $0.map { Array($0.unicodeScalars) } })

        let sampleI = sampleC.map { $0.value }
        var sampleILines = sampleI.parsedLines(considering: .all)
        XCTAssertEqual(sampleILines.underestimatedCount, 1)
        XCTAssertEqual(Array(sampleILines).map(LineSequenceTests.convert), sampleLines.map { $0.map { $0.unicodeScalars.map { $0.value } } })
        sampleILines = sampleI.parsedLines(considering: .paranoid)
        XCTAssertEqual(sampleILines.underestimatedCount, 1)
        XCTAssertEqual(Array(sampleILines).map(LineSequenceTests.convert), sampleLines.map { $0.map { $0.unicodeScalars.map { $0.value } } })

        // Also test no terminators
        sampleCLines = sampleC.parsedLines(considering: [])
        XCTAssertEqual(Array(sampleCLines).map(LineSequenceTests.convert), [[sampleC, [UnicodeScalar]()]])
        sampleILines = sampleI.parsedLines(considering: [])
        XCTAssertEqual(Array(sampleILines).map(LineSequenceTests.convert), [[sampleI, [UInt32]()]])
    }

    // Test one line with several interpretations
    func testOneLine() {
        //            01234567890123456789012345678901234567 8 9
        let sample = "There is normally one line break here.\r\n"
        let sampleLinesStrict = [["There is normally one line break here.", "\r\n"]]
        let sampleLinesCr = [["There is normally one line break here.", "\r"], ["\n", ""]]
        let sampleLinesLf = [["There is normally one line break here.\r", "\n"]]
        let sampleLinesCrOrLf = [["There is normally one line break here.", "\r"], ["", "\n"]]

        let sampleC = Array(sample.unicodeScalars)
        var sampleCLines = sampleC.parsedLines(considering: .strict)
        XCTAssertEqual(Array(sampleCLines).map(LineSequenceTests.convert), sampleLinesStrict.map { $0.map { Array($0.unicodeScalars) } })
        sampleCLines = sampleC.parsedLines(considering: .cr)
        XCTAssertEqual(Array(sampleCLines).map(LineSequenceTests.convert), sampleLinesCr.map { $0.map { Array($0.unicodeScalars) } })
        sampleCLines = sampleC.parsedLines(considering: .lf)
        XCTAssertEqual(Array(sampleCLines).map(LineSequenceTests.convert), sampleLinesLf.map { $0.map { Array($0.unicodeScalars) } })
        sampleCLines = sampleC.parsedLines(considering: [.cr, .lf])
        XCTAssertEqual(Array(sampleCLines).map(LineSequenceTests.convert), sampleLinesCrOrLf.map { $0.map { Array($0.unicodeScalars) } })

        let sampleI = sampleC.map { $0.value }
        var sampleILines = sampleI.parsedLines(considering: .strict)
        XCTAssertEqual(Array(sampleILines).map(LineSequenceTests.convert), sampleLinesStrict.map { $0.map { $0.unicodeScalars.map { $0.value } } })
        sampleILines = sampleI.parsedLines(considering: .cr)
        XCTAssertEqual(Array(sampleILines).map(LineSequenceTests.convert), sampleLinesCr.map { $0.map { $0.unicodeScalars.map { $0.value } } })
        sampleILines = sampleI.parsedLines(considering: .lf)
        XCTAssertEqual(Array(sampleILines).map(LineSequenceTests.convert), sampleLinesLf.map { $0.map { $0.unicodeScalars.map { $0.value } } })
        sampleILines = sampleI.parsedLines(considering: [.cr, .lf])
        XCTAssertEqual(Array(sampleILines).map(LineSequenceTests.convert), sampleLinesCrOrLf.map { $0.map { $0.unicodeScalars.map { $0.value } } })
    }

    static var allTests = [
        ("testEmpty", testEmpty),
        ("testUnterminated", testUnterminated),
        ("testAllTerminators", testAllTerminators),
        ("testOneLine", testOneLine),
    ]

}
