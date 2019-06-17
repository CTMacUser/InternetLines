//
//  LineTerminatorLocationsTests.swift
//  InternetLinesTests
//
//  Created by Daryle Walker on 6/15/19.
//

import XCTest
@testable import InternetLines


class LineTerminatorLocationsTests: XCTestCase {

    // Test the raw values of the search-target options.
    func testLineTerminatorSearchTargets() {
        XCTAssertEqual(LineTerminatorSearchTargets.lf.rawValue, 1)
        XCTAssertEqual(LineTerminatorSearchTargets.crlf.rawValue, 2)
        XCTAssertEqual(LineTerminatorSearchTargets.crcrlf.rawValue, 4)
        XCTAssertEqual(LineTerminatorSearchTargets.cr.rawValue, 8)

        XCTAssertEqual(LineTerminatorSearchTargets.strict.rawValue, 0x02)
        XCTAssertEqual(LineTerminatorSearchTargets.standard.rawValue, 0x0B)
        XCTAssertEqual(LineTerminatorSearchTargets.paranoid.rawValue, 0x0F)

        XCTAssertEqual(LineTerminatorSearchTargets.all.rawValue, ~0)
    }

    // Test search code for line-breaking sequence locations.
    func testLineTerminatorLocationsAsSequence() {
        //                  012345678 9012345678 901234567890 1 234567890 1 2 3456
        let sample = Array("The quick\rbrown fox\njumped over\r\nthe lazy\r\r\ndog".unicodeScalars)

        // Check every kind of line terminator.
        let allSample = LineTerminatorLocations(base: sample, targets: .all)
        XCTAssertEqual(Array(AnySequence(allSample)), [9..<10, 19..<20, 31..<33, 41..<44])

        let paranoidSample = LineTerminatorLocations(base: sample, targets: .paranoid)
        XCTAssertEqual(Array(AnySequence(paranoidSample)), [9..<10, 19..<20, 31..<33, 41..<44])

        // Check restricted set of terminators
        // (Without support for CR-CRLF, it breaks down to CR then CRLF.)
        let standardSample = LineTerminatorLocations(base: sample, targets: .standard)
        XCTAssertEqual(Array(AnySequence(standardSample)), [9..<10, 19..<20, 31..<33, 41..<42, 42..<44])

        // (Only the last part of the CR-CRLF is read in.)
        let strictSample = LineTerminatorLocations(base: sample, targets: .strict)
        XCTAssertEqual(Array(AnySequence(strictSample)), [31..<33, 42..<44])

        // Check what happens when no line terminators are searched for.
        let noSample = LineTerminatorLocations(base: sample, targets: [])
        XCTAssertTrue(Array(AnySequence(noSample)).isEmpty)

        // Check each terminator individually, noting CR-CRLF -> CRLF, etc.
        let crSample = LineTerminatorLocations(base: sample, targets: .cr)
        XCTAssertEqual(Array(AnySequence(crSample)), [9..<10, 31..<32, 41..<42, 42..<43])

        let lfSample = LineTerminatorLocations(base: sample, targets: .lf)
        XCTAssertEqual(Array(AnySequence(lfSample)), [19..<20, 32..<33, 43..<44])

        let crlfSample = LineTerminatorLocations(base: sample, targets: .crlf)
        XCTAssertEqual(Array(AnySequence(crlfSample)), [31..<33, 42..<44])

        let crcrlfSample = LineTerminatorLocations(base: sample, targets: .crcrlf)
        XCTAssertEqual(Array(AnySequence(crcrlfSample)), [41..<44])

        // Check an empty string.
        let allEmpty = LineTerminatorLocations(base: [UnicodeScalar](), targets: .all)
        XCTAssertTrue(Array(AnySequence(allEmpty)).isEmpty)

        // Check underestimated count when a line terminator starts the text.
        XCTAssertEqual(allEmpty.underestimatedCount, 0)
        XCTAssertEqual(LineTerminatorLocations(base: sample.dropFirst(9), targets: .cr).underestimatedCount, 1)
        XCTAssertEqual(LineTerminatorLocations(base: sample.dropFirst(9), targets: .lf).underestimatedCount, 0)
    }

    // Test search code for line-breaking sequence locations.
    func testLineTerminatorLocationsAsCollection() {
        //                  012345678 9012345678 901234567890 1 234567890 1 2 3456
        let sample = Array("The quick\rbrown fox\njumped over\r\nthe lazy\r\r\ndog".unicodeScalars)

        // Check every kind of line terminator.
        let allSample = LineTerminatorLocations(base: sample, targets: .all)
        XCTAssertFalse(allSample.isEmpty)
        XCTAssertEqual(allSample.count, 4)
        XCTAssertEqual(allSample.first, 9..<10)
        XCTAssertEqual(allSample.indices.map({allSample[$0]}), [9..<10, 19..<20, 31..<33, 41..<44])

        let paranoidSample = LineTerminatorLocations(base: sample, targets: .paranoid)
        XCTAssertEqual(Array(paranoidSample.indices.map({paranoidSample[$0]})), [9..<10, 19..<20, 31..<33, 41..<44])

        // Check restricted set of terminators
        // (Without support for CR-CRLF, it breaks down to CR then CRLF.)
        let standardSample = LineTerminatorLocations(base: sample, targets: .standard)
        XCTAssertEqual(Array(standardSample.indices.map({standardSample[$0]})), [9..<10, 19..<20, 31..<33, 41..<42, 42..<44])

        // (Only the last part of the CR-CRLF is read in.)
        let strictSample = LineTerminatorLocations(base: sample, targets: .strict)
        XCTAssertEqual(Array(strictSample.indices.map({strictSample[$0]})), [31..<33, 42..<44])

        // Check what happens when no line terminators are searched for.
        let noSample = LineTerminatorLocations(base: sample, targets: [])
        XCTAssertTrue(noSample.isEmpty)

        // Check each terminator individually, noting CR-CRLF -> CRLF, etc.
        let crSample = LineTerminatorLocations(base: sample, targets: .cr)
        XCTAssertEqual(Array(crSample.indices.map({crSample[$0]})), [9..<10, 31..<32, 41..<42, 42..<43])

        let lfSample = LineTerminatorLocations(base: sample, targets: .lf)
        XCTAssertEqual(Array(lfSample.indices.map({lfSample[$0]})), [19..<20, 32..<33, 43..<44])

        let crlfSample = LineTerminatorLocations(base: sample, targets: .crlf)
        XCTAssertEqual(Array(crlfSample.indices.map({crlfSample[$0]})), [31..<33, 42..<44])

        let crcrlfSample = LineTerminatorLocations(base: sample, targets: .crcrlf)
        XCTAssertEqual(Array(crcrlfSample.indices.map({crcrlfSample[$0]})), [41..<44])

        // Check an empty string.
        let allEmpty = LineTerminatorLocations(base: [UnicodeScalar](), targets: .all)
        XCTAssertTrue(allEmpty.isEmpty)
    }

    // Test backward-searching code
    func testLineTerminatorLocationsAsBidirectionalCollection() {
        //                  012345678 9012345678 901234567890 1 234567890 1 2 3456
        let sample = Array("The quick\rbrown fox\njumped over\r\nthe lazy\r\r\ndog".unicodeScalars)

        // Check every kind of line terminator.
        let allSample = LineTerminatorLocations(base: sample, targets: .all)
        XCTAssertEqual(Array(allSample.indices), allSample.reversed().indices.map { allSample.index(before: $0.base) }.reversed())

        let paranoidSample = LineTerminatorLocations(base: sample, targets: .paranoid)
        XCTAssertEqual(Array(paranoidSample.indices), paranoidSample.reversed().indices.map { paranoidSample.index(before: $0.base) }.reversed())

        // Check restricted set of terminators
        // (Without support for CR-CRLF, it breaks down to CR then CRLF.)
        let standardSample = LineTerminatorLocations(base: sample, targets: .standard)
        XCTAssertEqual(Array(standardSample.indices), standardSample.reversed().indices.map { standardSample.index(before: $0.base) }.reversed())

        // (Only the last part of the CR-CRLF is read in.)
        let strictSample = LineTerminatorLocations(base: sample, targets: .strict)
        XCTAssertEqual(Array(strictSample.indices), strictSample.reversed().indices.map { strictSample.index(before: $0.base) }.reversed())

        // Check what happens when no line terminators are searched for.
        let noSample = LineTerminatorLocations(base: sample, targets: [])
        XCTAssertTrue(noSample.reversed().isEmpty)

        // Check each terminator individually, noting CR-CRLF -> CRLF, etc.
        let crSample = LineTerminatorLocations(base: sample, targets: .cr)
        XCTAssertEqual(Array(crSample.indices), crSample.reversed().indices.map { crSample.index(before: $0.base) }.reversed())

        let lfSample = LineTerminatorLocations(base: sample, targets: .lf)
        XCTAssertEqual(Array(lfSample.indices), lfSample.reversed().indices.map { lfSample.index(before: $0.base) }.reversed())

        let crlfSample = LineTerminatorLocations(base: sample, targets: .crlf)
        XCTAssertEqual(Array(crlfSample.indices), crlfSample.reversed().indices.map { crlfSample.index(before: $0.base) }.reversed())

        let crcrlfSample = LineTerminatorLocations(base: sample, targets: .crcrlf)
        XCTAssertEqual(Array(crcrlfSample.indices), crcrlfSample.reversed().indices.map { crcrlfSample.index(before: $0.base) }.reversed())

        // Check an empty string.
        let allEmpty = LineTerminatorLocations(base: [UnicodeScalar](), targets: .all)
        XCTAssertTrue(allEmpty.reversed().isEmpty)
    }

    static var allTests = [
        ("testLineTerminatorSearchTargets", testLineTerminatorSearchTargets),
        ("testLineTerminatorLocationsAsSequence", testLineTerminatorLocationsAsSequence),
        ("testLineTerminatorLocationsAsCollection", testLineTerminatorLocationsAsCollection),
        ("testLineTerminatorLocationsAsBidirectionalCollection", testLineTerminatorLocationsAsBidirectionalCollection),
    ]

}
