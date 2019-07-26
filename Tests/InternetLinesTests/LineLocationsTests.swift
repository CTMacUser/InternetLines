//
//  LineLocationsTests.swift
//  InternetLinesTests
//
//  Created by Daryle Walker on 7/24/19.
//

import XCTest
@testable import InternetLines


class LineLocationsTests: XCTestCase {

    // A source of text.
    //                      012345678 9012345678 901234567890 1 234567890 1 2 3456
    static let rawSample = "The quick\rbrown fox\njumped over\r\nthe lazy\r\r\ndog"
    static let charSample = Array(rawSample.unicodeScalars)
    static let intSample = charSample.map { $0.value }

    // Another source of text, one that ends with a line break.
    //                       012345678 9 0123456789012345678 9 0
    static let rawSample2 = "This ends\r\nwith a line break.\r\n"
    static let charSample2 = Array(rawSample2.unicodeScalars)
    static let intSample2 = charSample2.map { $0.value }

    // A third text source, ends with a line break, no other breaks.
    //                       01234567890123456789012345678 9 0
    static let rawSample3 = "There is only one line break.\r\n"
    static let charSample3 = Array(rawSample3.unicodeScalars)
    static let intSample3 = charSample3.map { $0.value }

    // Convert a double range to a 3-element array.
    static func convert<T>(_ x: (start: T, border: T, end: T)) -> [T] {
        return [x.start, x.border, x.end]
    }

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // Test search code for line locations.
    func testLineLocationsAsSequence() {
        // Check every kind of line terminator.
        let allSampleC = LineLocationsTests.charSample.lineLocations(considering: .all)
        let allSampleI = LineLocationsTests.intSample.lineLocations(considering: .all)
        XCTAssertEqual(AnySequence(allSampleC).map(LineLocationsTests.convert), [[0, 9, 10], [10, 19, 20], [20, 31, 33], [33, 41, 44], [44, 47, 47]])
        XCTAssertEqual(AnySequence(allSampleI).map(LineLocationsTests.convert), [[0, 9, 10], [10, 19, 20], [20, 31, 33], [33, 41, 44], [44, 47, 47]])

        let paranoidSampleC = LineLocationsTests.charSample.lineLocations(considering: .paranoid)
        let paranoidSampleI = LineLocationsTests.intSample.lineLocations(considering: .paranoid)
        XCTAssertEqual(AnySequence(paranoidSampleC).map(LineLocationsTests.convert), [[0, 9, 10], [10, 19, 20], [20, 31, 33], [33, 41, 44], [44, 47, 47]])
        XCTAssertEqual(AnySequence(paranoidSampleI).map(LineLocationsTests.convert), [[0, 9, 10], [10, 19, 20], [20, 31, 33], [33, 41, 44], [44, 47, 47]])

        // Check restricted set of terminators
        // (Without support for CR-CRLF, it breaks down to CR then CRLF.)
        let standardSampleC = LineLocationsTests.charSample.lineLocations(considering: .standard)
        let standardSampleI = LineLocationsTests.intSample.lineLocations(considering: .standard)
        XCTAssertEqual(AnySequence(standardSampleC).map(LineLocationsTests.convert), [[0, 9, 10], [10, 19, 20], [20, 31, 33], [33, 41, 42], [42, 42, 44], [44, 47, 47]])
        XCTAssertEqual(AnySequence(standardSampleI).map(LineLocationsTests.convert), [[0, 9, 10], [10, 19, 20], [20, 31, 33], [33, 41, 42], [42, 42, 44], [44, 47, 47]])

        // (Only the last part of the CR-CRLF is read in.)
        let strictSampleC = LineLocationsTests.charSample.lineLocations(considering: .strict)
        let strictSampleI = LineLocationsTests.intSample.lineLocations(considering: .strict)
        XCTAssertEqual(AnySequence(strictSampleC).map(LineLocationsTests.convert), [[0, 31, 33], [33, 42, 44], [44, 47, 47]])
        XCTAssertEqual(AnySequence(strictSampleI).map(LineLocationsTests.convert), [[0, 31, 33], [33, 42, 44], [44, 47, 47]])

        // Check what happens when no line terminators are searched for.
        let noSampleC = LineLocationsTests.charSample.lineLocations(considering: [])
        let noSampleI = LineLocationsTests.intSample.lineLocations(considering: [])
        XCTAssertEqual(AnySequence(noSampleC).map(LineLocationsTests.convert), [[0, 47, 47]])
        XCTAssertEqual(AnySequence(noSampleI).map(LineLocationsTests.convert), [[0, 47, 47]])

        // Check each terminator individually, noting CR-CRLF -> CRLF, etc.
        let crSampleC = LineLocationsTests.charSample.lineLocations(considering: .cr)
        let crSampleI = LineLocationsTests.intSample.lineLocations(considering: .cr)
        XCTAssertEqual(AnySequence(crSampleC).map(LineLocationsTests.convert), [[0, 9, 10], [10, 31, 32], [32, 41, 42], [42, 42, 43], [43, 47, 47]])
        XCTAssertEqual(AnySequence(crSampleI).map(LineLocationsTests.convert), [[0, 9, 10], [10, 31, 32], [32, 41, 42], [42, 42, 43], [43, 47, 47]])

        let lfSampleC = LineLocationsTests.charSample.lineLocations(considering: .lf)
        let lfSampleI = LineLocationsTests.intSample.lineLocations(considering: .lf)
        XCTAssertEqual(AnySequence(lfSampleC).map(LineLocationsTests.convert), [[0, 19, 20], [20, 32, 33], [33, 43, 44], [44, 47, 47]])
        XCTAssertEqual(AnySequence(lfSampleI).map(LineLocationsTests.convert), [[0, 19, 20], [20, 32, 33], [33, 43, 44], [44, 47, 47]])

        let crlfSampleC = LineLocationsTests.charSample.lineLocations(considering: .crlf)
        let crlfSampleI = LineLocationsTests.intSample.lineLocations(considering: .crlf)
        XCTAssertEqual(AnySequence(crlfSampleC).map(LineLocationsTests.convert), [[0, 31, 33], [33, 42, 44], [44, 47, 47]])
        XCTAssertEqual(AnySequence(crlfSampleI).map(LineLocationsTests.convert), [[0, 31, 33], [33, 42, 44], [44, 47, 47]])

        let crcrlfSampleC = LineLocationsTests.charSample.lineLocations(considering: .crcrlf)
        let crcrlfSampleI = LineLocationsTests.intSample.lineLocations(considering: .crcrlf)
        XCTAssertEqual(AnySequence(crcrlfSampleC).map(LineLocationsTests.convert), [[0, 41, 44], [44, 47, 47]])
        XCTAssertEqual(AnySequence(crcrlfSampleI).map(LineLocationsTests.convert), [[0, 41, 44], [44, 47, 47]])

        // Check an empty string.
        let allEmptyC = [UnicodeScalar]().lineLocations(considering: .all)
        let allEmptyI = [UInt32]().lineLocations(considering: .all)
        XCTAssertTrue(Array(AnySequence(allEmptyC)).isEmpty)
        XCTAssertTrue(Array(AnySequence(allEmptyI)).isEmpty)

        // Check a string that ends with a line break.
        let sample2C = LineLocationsTests.charSample2.lineLocations(considering: .crlf)
        let sample2I = LineLocationsTests.intSample2.lineLocations(considering: .crlf)
        XCTAssertEqual(AnySequence(sample2C).map(LineLocationsTests.convert), [[0, 9, 11], [11, 29, 31]])
        XCTAssertEqual(AnySequence(sample2I).map(LineLocationsTests.convert), [[0, 9, 11], [11, 29, 31]])

        let sample3C = LineLocationsTests.charSample3.lineLocations(considering: .crlf)
        let sample3I = LineLocationsTests.intSample3.lineLocations(considering: .crlf)
        XCTAssertEqual(AnySequence(sample3C).map(LineLocationsTests.convert), [[0, 29, 31]])
        XCTAssertEqual(AnySequence(sample3I).map(LineLocationsTests.convert), [[0, 29, 31]])

        // Check underestimated count when a line terminator starts the text.
        XCTAssertEqual(allEmptyC.underestimatedCount, 0)
        XCTAssertEqual(allEmptyI.underestimatedCount, 0)
        XCTAssertEqual(LineLocationsTests.charSample.dropFirst(9).lineLocations(considering: .cr).underestimatedCount, 1)
        XCTAssertEqual(LineLocationsTests.charSample.dropFirst(9).lineLocations(considering: .lf).underestimatedCount, 1)
        XCTAssertEqual(LineLocationsTests.intSample.dropFirst(9).lineLocations(considering: .cr).underestimatedCount, 1)
        XCTAssertEqual(LineLocationsTests.intSample.dropFirst(9).lineLocations(considering: .lf).underestimatedCount, 1)
    }

    // Test search code for line locations.
    func testLineLocationsAsCollection() {
        // Check every kind of line terminator.
        let allSampleC = LineLocationsTests.charSample.lineLocations(considering: .all)
        let allSampleI = LineLocationsTests.intSample.lineLocations(considering: .all)
        XCTAssertFalse(allSampleC.isEmpty)
        XCTAssertEqual(allSampleC.count, 5)
        XCTAssertEqual(allSampleC.first.map(LineLocationsTests.convert), [0, 9, 10])
        XCTAssertEqual(allSampleC.indices.map { LineLocationsTests.convert(allSampleC[$0]) }, [[0, 9, 10], [10, 19, 20], [20, 31, 33], [33, 41, 44], [44, 47, 47]])
        XCTAssertFalse(allSampleI.isEmpty)
        XCTAssertEqual(allSampleI.count, 5)
        XCTAssertEqual(allSampleI.first.map(LineLocationsTests.convert), [0, 9, 10])
        XCTAssertEqual(allSampleI.indices.map { LineLocationsTests.convert(allSampleI[$0]) }, [[0, 9, 10], [10, 19, 20], [20, 31, 33], [33, 41, 44], [44, 47, 47]])

        let paranoidSampleC = LineLocationsTests.charSample.lineLocations(considering: .paranoid)
        let paranoidSampleI = LineLocationsTests.intSample.lineLocations(considering: .paranoid)
        XCTAssertEqual(paranoidSampleC.indices.map { LineLocationsTests.convert(paranoidSampleC[$0]) }, [[0, 9, 10], [10, 19, 20], [20, 31, 33], [33, 41, 44], [44, 47, 47]])
        XCTAssertEqual(paranoidSampleI.indices.map { LineLocationsTests.convert(paranoidSampleI[$0]) }, [[0, 9, 10], [10, 19, 20], [20, 31, 33], [33, 41, 44], [44, 47, 47]])

        // Check restricted set of terminators
        // (Without support for CR-CRLF, it breaks down to CR then CRLF.)
        let standardSampleC = LineLocationsTests.charSample.lineLocations(considering: .standard)
        let standardSampleI = LineLocationsTests.intSample.lineLocations(considering: .standard)
        XCTAssertEqual(standardSampleC.indices.map { LineLocationsTests.convert(standardSampleC[$0]) }, [[0, 9, 10], [10, 19, 20], [20, 31, 33], [33, 41, 42], [42, 42, 44], [44, 47, 47]])
        XCTAssertEqual(standardSampleI.indices.map { LineLocationsTests.convert(standardSampleI[$0]) }, [[0, 9, 10], [10, 19, 20], [20, 31, 33], [33, 41, 42], [42, 42, 44], [44, 47, 47]])

        // (Only the last part of the CR-CRLF is read in.)
        let strictSampleC = LineLocationsTests.charSample.lineLocations(considering: .strict)
        let strictSampleI = LineLocationsTests.intSample.lineLocations(considering: .strict)
        XCTAssertEqual(strictSampleC.indices.map { LineLocationsTests.convert(strictSampleC[$0]) }, [[0, 31, 33], [33, 42, 44], [44, 47, 47]])
        XCTAssertEqual(strictSampleI.indices.map { LineLocationsTests.convert(strictSampleI[$0]) }, [[0, 31, 33], [33, 42, 44], [44, 47, 47]])

        // Check what happens when no line terminators are searched for.
        let noSampleC = LineLocationsTests.charSample.lineLocations(considering: [])
        let noSampleI = LineLocationsTests.intSample.lineLocations(considering: [])
        XCTAssertEqual(noSampleC.indices.map { LineLocationsTests.convert(noSampleC[$0]) }, [[0, 47, 47]])
        XCTAssertEqual(noSampleI.indices.map { LineLocationsTests.convert(noSampleI[$0]) }, [[0, 47, 47]])

        // Check each terminator individually, noting CR-CRLF -> CRLF, etc.
        let crSampleC = LineLocationsTests.charSample.lineLocations(considering: .cr)
        let crSampleI = LineLocationsTests.intSample.lineLocations(considering: .cr)
        XCTAssertEqual(crSampleC.indices.map { LineLocationsTests.convert(crSampleC[$0]) }, [[0, 9, 10], [10, 31, 32], [32, 41, 42], [42, 42, 43], [43, 47, 47]])
        XCTAssertEqual(crSampleI.indices.map { LineLocationsTests.convert(crSampleI[$0]) }, [[0, 9, 10], [10, 31, 32], [32, 41, 42], [42, 42, 43], [43, 47, 47]])

        let lfSampleC = LineLocationsTests.charSample.lineLocations(considering: .lf)
        let lfSampleI = LineLocationsTests.intSample.lineLocations(considering: .lf)
        XCTAssertEqual(lfSampleC.indices.map { LineLocationsTests.convert(lfSampleC[$0]) }, [[0, 19, 20], [20, 32, 33], [33, 43, 44], [44, 47, 47]])
        XCTAssertEqual(lfSampleI.indices.map { LineLocationsTests.convert(lfSampleI[$0]) }, [[0, 19, 20], [20, 32, 33], [33, 43, 44], [44, 47, 47]])

        let crlfSampleC = LineLocationsTests.charSample.lineLocations(considering: .crlf)
        let crlfSampleI = LineLocationsTests.intSample.lineLocations(considering: .crlf)
        XCTAssertEqual(crlfSampleC.indices.map { LineLocationsTests.convert(crlfSampleC[$0]) }, [[0, 31, 33], [33, 42, 44], [44, 47, 47]])
        XCTAssertEqual(crlfSampleI.indices.map { LineLocationsTests.convert(crlfSampleI[$0]) }, [[0, 31, 33], [33, 42, 44], [44, 47, 47]])

        let crcrlfSampleC = LineLocationsTests.charSample.lineLocations(considering: .crcrlf)
        let crcrlfSampleI = LineLocationsTests.intSample.lineLocations(considering: .crcrlf)
        XCTAssertEqual(crcrlfSampleC.indices.map { LineLocationsTests.convert(crcrlfSampleC[$0]) }, [[0, 41, 44], [44, 47, 47]])
        XCTAssertEqual(crcrlfSampleI.indices.map { LineLocationsTests.convert(crcrlfSampleI[$0]) }, [[0, 41, 44], [44, 47, 47]])

        // Check an empty string.
        let allEmptyC = [UnicodeScalar]().lineLocations(considering: .all)
        let allEmptyI = [UInt32]().lineLocations(considering: .all)
        XCTAssertTrue(allEmptyC.isEmpty)
        XCTAssertTrue(allEmptyI.isEmpty)

        // Check a string that ends with a line break.
        let sample2C = LineLocationsTests.charSample2.lineLocations(considering: .crlf)
        let sample2I = LineLocationsTests.intSample2.lineLocations(considering: .crlf)
        XCTAssertEqual(sample2C.indices.map { LineLocationsTests.convert(sample2C[$0]) }, [[0, 9, 11], [11, 29, 31]])
        XCTAssertEqual(sample2I.indices.map { LineLocationsTests.convert(sample2I[$0]) }, [[0, 9, 11], [11, 29, 31]])

        let sample3C = LineLocationsTests.charSample3.lineLocations(considering: .crlf)
        let sample3I = LineLocationsTests.intSample3.lineLocations(considering: .crlf)
        XCTAssertEqual(sample3C.indices.map { LineLocationsTests.convert(sample3C[$0]) }, [[0, 29, 31]])
        XCTAssertEqual(sample3I.indices.map { LineLocationsTests.convert(sample3I[$0]) }, [[0, 29, 31]])
    }

    // Test backward-searching code
    func testLineLocationsAsBidirectionalCollection() {
        // Check every kind of line terminator.
        let allSampleC = LineLocationsTests.charSample.lineLocations(considering: .all)
        let allSampleI = LineLocationsTests.intSample.lineLocations(considering: .all)
        XCTAssertEqual(Array(allSampleC.indices), allSampleC.reversed().indices.map { allSampleC.index(before: $0.base) }.reversed())
        XCTAssertEqual(Array(allSampleI.indices), allSampleI.reversed().indices.map { allSampleI.index(before: $0.base) }.reversed())

        let paranoidSampleC = LineLocationsTests.charSample.lineLocations(considering: .paranoid)
        let paranoidSampleI = LineLocationsTests.intSample.lineLocations(considering: .paranoid)
        XCTAssertEqual(Array(paranoidSampleC.indices), paranoidSampleC.reversed().indices.map { paranoidSampleC.index(before: $0.base) }.reversed())
        XCTAssertEqual(Array(paranoidSampleI.indices), paranoidSampleI.reversed().indices.map { paranoidSampleI.index(before: $0.base) }.reversed())

        // Check restricted set of terminators
        // (Without support for CR-CRLF, it breaks down to CR then CRLF.)
        let standardSampleC = LineLocationsTests.charSample.lineLocations(considering: .standard)
        let standardSampleI = LineLocationsTests.intSample.lineLocations(considering: .standard)
        XCTAssertEqual(Array(standardSampleC.indices), standardSampleC.reversed().indices.map { standardSampleC.index(before: $0.base) }.reversed())
        XCTAssertEqual(Array(standardSampleI.indices), standardSampleI.reversed().indices.map { standardSampleI.index(before: $0.base) }.reversed())

        // (Only the last part of the CR-CRLF is read in.)
        let strictSampleC = LineLocationsTests.charSample.lineLocations(considering: .strict)
        let strictSampleI = LineLocationsTests.intSample.lineLocations(considering: .strict)
        XCTAssertEqual(Array(strictSampleC.indices), strictSampleC.reversed().indices.map { strictSampleC.index(before: $0.base) }.reversed())
        XCTAssertEqual(Array(strictSampleI.indices), strictSampleI.reversed().indices.map { strictSampleI.index(before: $0.base) }.reversed())

        // Check what happens when no line terminators are searched for.
        let noSampleC = LineLocationsTests.charSample.lineLocations(considering: [])
        let noSampleI = LineLocationsTests.intSample.lineLocations(considering: [])
        XCTAssertEqual(Array(noSampleC.indices), noSampleC.reversed().indices.map { noSampleC.index(before: $0.base) }.reversed())
        XCTAssertEqual(Array(noSampleI.indices), noSampleI.reversed().indices.map { noSampleI.index(before: $0.base) }.reversed())

        // Check each terminator individually, noting CR-CRLF -> CRLF, etc.
        let crSampleC = LineLocationsTests.charSample.lineLocations(considering: .cr)
        let crSampleI = LineLocationsTests.intSample.lineLocations(considering: .cr)
        XCTAssertEqual(Array(crSampleC.indices), crSampleC.reversed().indices.map { crSampleC.index(before: $0.base) }.reversed())
        XCTAssertEqual(Array(crSampleI.indices), crSampleI.reversed().indices.map { crSampleI.index(before: $0.base) }.reversed())

        let lfSampleC = LineLocationsTests.charSample.lineLocations(considering: .lf)
        let lfSampleI = LineLocationsTests.intSample.lineLocations(considering: .lf)
        XCTAssertEqual(Array(lfSampleC.indices), lfSampleC.reversed().indices.map { lfSampleC.index(before: $0.base) }.reversed())
        XCTAssertEqual(Array(lfSampleI.indices), lfSampleI.reversed().indices.map { lfSampleI.index(before: $0.base) }.reversed())

        let crlfSampleC = LineLocationsTests.charSample.lineLocations(considering: .crlf)
        let crlfSampleI = LineLocationsTests.intSample.lineLocations(considering: .crlf)
        XCTAssertEqual(Array(crlfSampleC.indices), crlfSampleC.reversed().indices.map { crlfSampleC.index(before: $0.base) }.reversed())
        XCTAssertEqual(Array(crlfSampleI.indices), crlfSampleI.reversed().indices.map { crlfSampleI.index(before: $0.base) }.reversed())

        let crcrlfSampleC = LineLocationsTests.charSample.lineLocations(considering: .crcrlf)
        let crcrlfSampleI = LineLocationsTests.intSample.lineLocations(considering: .crcrlf)
        XCTAssertEqual(Array(crcrlfSampleC.indices), crcrlfSampleC.reversed().indices.map { crcrlfSampleC.index(before: $0.base) }.reversed())
        XCTAssertEqual(Array(crcrlfSampleI.indices), crcrlfSampleI.reversed().indices.map { crcrlfSampleI.index(before: $0.base) }.reversed())

        // Check an empty string.
        let allEmptyC = [UnicodeScalar]().lineLocations(considering: .all)
        let allEmptyI = [UInt32]().lineLocations(considering: .all)
        XCTAssertTrue(allEmptyC.reversed().isEmpty)
        XCTAssertTrue(allEmptyI.reversed().isEmpty)

        // Check a string that ends with a line break.
        let sample2C = LineLocationsTests.charSample2.lineLocations(considering: .crlf)
        let sample2I = LineLocationsTests.intSample2.lineLocations(considering: .crlf)
        XCTAssertEqual(Array(sample2C.indices), sample2C.reversed().indices.map { sample2C.index(before: $0.base) }.reversed())
        XCTAssertEqual(Array(sample2I.indices), sample2I.reversed().indices.map { sample2I.index(before: $0.base) }.reversed())

        let sample3C = LineLocationsTests.charSample3.lineLocations(considering: .crlf)
        let sample3I = LineLocationsTests.intSample3.lineLocations(considering: .crlf)
        XCTAssertEqual(Array(sample3C.indices), sample3C.reversed().indices.map { sample3C.index(before: $0.base) }.reversed())
        XCTAssertEqual(Array(sample3I.indices), sample3I.reversed().indices.map { sample3I.index(before: $0.base) }.reversed())
    }

    static var allTests = [
        ("testLineLocationsAsSequence", testLineLocationsAsSequence),
        ("testLineLocationsAsCollection", testLineLocationsAsCollection),
        ("testLineLocationsAsBidirectionalCollection", testLineLocationsAsBidirectionalCollection),
    ]

}
