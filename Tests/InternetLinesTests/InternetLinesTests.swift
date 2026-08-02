/// A test suite for a stream that splits a collection into lines.
//
// SPDX-FileCopyrightText: © 2026 Daryle Walker (@CTMacUser)
// SPDX-License-Identifier: MIT

import Testing

@testable import InternetLines

/// Validates that various line-ending characters correctly split an
/// input stream into lines,
/// covering both collection-based and sequence-based processing.
@Test("Checking each kind of splitting sequence")
func linesSplitting() async throws {
  let input = "Line1\nLine2\rLine3\r\nLine4\u{000B}Line5\u{000C}Line6".utf8
  let collectionLines = await input.internetLines.reduce(into: []) {
    $0.append($1)
  }

  #expect(collectionLines.count == 6)

  #expect(collectionLines[0].cap == .lineFeed)
  #expect(input[collectionLines[0].lineRange].elementsEqual("Line1".utf8))

  #expect(collectionLines[1].cap == .carriageReturn)
  #expect(input[collectionLines[1].lineRange].elementsEqual("Line2".utf8))

  #expect(collectionLines[2].cap == .crlf)
  #expect(input[collectionLines[2].lineRange].elementsEqual("Line3".utf8))

  #expect(collectionLines[3].cap == .lineTabulation)
  #expect(input[collectionLines[3].lineRange].elementsEqual("Line4".utf8))

  #expect(collectionLines[4].cap == .formFeed)
  #expect(input[collectionLines[4].lineRange].elementsEqual("Line5".utf8))

  #expect(collectionLines[5].cap == .nothing)
  #expect(input[collectionLines[5].lineRange].elementsEqual("Line6".utf8))

  // Sequence version
  let inputSequence = AnySequence(input)
  let sequenceLines = await inputSequence.internetLines.reduce(into: []) {
    $0.append($1)
  }

  #expect(sequenceLines.count == 6)

  #expect(sequenceLines[0] == (line: Array("Line1".utf8), cap: .lineFeed))
  #expect(sequenceLines[1] == (line: Array("Line2".utf8), cap: .carriageReturn))
  #expect(sequenceLines[2] == (line: Array("Line3".utf8), cap: .crlf))
  #expect(sequenceLines[3] == (line: Array("Line4".utf8), cap: .lineTabulation))
  #expect(sequenceLines[4] == (line: Array("Line5".utf8), cap: .formFeed))
  #expect(sequenceLines[5] == (line: Array("Line6".utf8), cap: .nothing))
}

/// Validates the string representation and deserialization (round-trip) of
/// all `InternetLineTerminator` enum cases.
@Test("Printing tests")
func printing() async throws {
  typealias Terminator = InternetLineTerminator

  let terminators = Array(Terminator.allCases)
  let terminatorTexts = terminators.map(String.init(describing:))
  #expect(
    terminatorTexts == [
      "nothing", "lineFeed", "lineTabulation", "formFeed", "carriageReturn",
      "crlf",
    ]
  )
  #expect(terminatorTexts.compactMap(Terminator.init(_:)) == terminators)
}

/// Validates, using parameterized testing,
/// that each `InternetLineTerminator` correctly marks the end of a line when
/// appearing at the very end of an input stream.
@Test(
  "Check each line-ending sequence at the end of the input",
  arguments: InternetLineTerminator.allCases
)
func lastTerminator(_ terminator: InternetLineTerminator) async throws {
  let rawTestLine = "This is a test."
  let testLine = rawTestLine + terminator.rawValue
  let collectionLines = await testLine.utf8.internetLines.reduce(into: []) {
    $0.append($1)
  }
  let firstCollectionLine = try #require(collectionLines.first)
  #expect(
    Array(testLine[firstCollectionLine.lineRange].utf8)
      == Array(rawTestLine.utf8)
  )
  #expect(firstCollectionLine.cap == terminator)
  #expect(collectionLines.count == 1)

  let sequenceLines = await AnySequence(testLine.utf8).internetLines.reduce(
    into: []) {
      $0.append($1)
    }
  let firstSequenceLine = try #require(sequenceLines.first)
  #expect(firstSequenceLine.line == Array(rawTestLine.utf8))
  #expect(firstSequenceLine.cap == terminator)
  #expect(sequenceLines.count == 1)
}

/// A quick & dirty demostration.
@Test("Example from the 'README.md' file")
func basicExample() async throws {
  let input = "Line 1\r\nLine 2\nLine 3\rLine 4"
  let lines = await AnySequence(input.utf8)
    .internetLines
    .map { String(decoding: $0.line, as: UTF8.self) }
    .reduce(into: []) { $0.append($1) }
  #expect(lines == ["Line 1", "Line 2", "Line 3", "Line 4"])
}
