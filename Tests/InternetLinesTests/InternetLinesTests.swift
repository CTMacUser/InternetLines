/// Tests for sequences that split sequences of bytes into lines.
//
// SPDX-FileCopyrightText: © 2026 Daryle Walker (@CTMacUser)
// SPDX-License-Identifier: MIT

import Testing

@testable import InternetLines

/// Verifies that a collection of bytes is correctly split into lines.
///
/// This includes checking each line's content index range and their
/// terminator value.
/// Line terminations can be: a line feed, a vertical tab, a form-feed,
/// a carriage return, a carriage return followed by a line feed,
/// and nothing at all (which can at most apply at the end).
@Test("Check collection line-splitting")
func collectionLineSplitting() async throws {
  let input = "Line1\nLine2\rLine3\r\nLine4\u{000B}Line5\u{000C}Line6".utf8
  let collectionLines = await input.internetLines.collect()

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
}

/// Verifies that a synchronous sequence of bytes is correctly split into lines.
///
/// This includes checking the value of each line's content and
/// the terminator used.
/// Line terminations can be: a line feed, a vertical tab, a form-feed,
/// a carriage return, a carriage return followed by a line feed,
/// and nothing at all (which can at most apply at the end).
@Test("Check line-splitting for synchronous sequences")
func sequenceLineSplitting() async throws {
  let input = "Line1\nLine2\rLine3\r\nLine4\u{000B}Line5\u{000C}Line6".utf8
  let inputSequence = AnySequence(input)
  let sequenceLines = await inputSequence.internetLines.collect()

  #expect(sequenceLines.count == 6)

  #expect(sequenceLines[0] == (line: Array("Line1".utf8), cap: .lineFeed))
  #expect(sequenceLines[1] == (line: Array("Line2".utf8), cap: .carriageReturn))
  #expect(sequenceLines[2] == (line: Array("Line3".utf8), cap: .crlf))
  #expect(sequenceLines[3] == (line: Array("Line4".utf8), cap: .lineTabulation))
  #expect(sequenceLines[4] == (line: Array("Line5".utf8), cap: .formFeed))
  #expect(sequenceLines[5] == (line: Array("Line6".utf8), cap: .nothing))
}

/// Verifies that an asynchronous sequence of bytes is correctly split into
/// lines.
///
/// This includes checking the value of each line's content and
/// the terminator used.
/// Line terminations can be: a line feed, a vertical tab, a form-feed,
/// a carriage return, a carriage return followed by a line feed,
/// and nothing at all (which can at most apply at the end).
@Test("Check asynchronous line-splitting")
func asyncLineSplitting() async throws {
  let input = "Line1\nLine2\rLine3\r\nLine4\u{000B}Line5\u{000C}Line6".utf8
  let byteStream = AsyncStream<UInt8> { continuation in
    for byte in input {
      continuation.yield(byte)
    }
    continuation.finish()
  }
  let streamLines = await byteStream.internetLines.collect()

  #expect(streamLines.count == 6)

  #expect(streamLines[0] == (line: Array("Line1".utf8), cap: .lineFeed))
  #expect(streamLines[1] == (line: Array("Line2".utf8), cap: .carriageReturn))
  #expect(streamLines[2] == (line: Array("Line3".utf8), cap: .crlf))
  #expect(streamLines[3] == (line: Array("Line4".utf8), cap: .lineTabulation))
  #expect(streamLines[4] == (line: Array("Line5".utf8), cap: .formFeed))
  #expect(streamLines[5] == (line: Array("Line6".utf8), cap: .nothing))
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
  #expect(Terminator("invalid") == nil)
}

/// Validates the raw representation and deserialization (round-trip) of
/// all `InternetLineTerminator` enum cases.
@Test("Raw representation tests")
func rawRepresentables() async throws {
  typealias Terminator = InternetLineTerminator

  let terminators = Array(Terminator.allCases)
  let terminatorRawValues = terminators.map(\.rawValue)

  #expect(
    terminatorRawValues.compactMap(Terminator.init(rawValue:)) == terminators
  )
  #expect(Terminator(rawValue: "invalid") == nil)
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
  let collectionLines = await testLine.utf8.internetLines.collect()
  let firstCollectionLine = try #require(collectionLines.first)
  #expect(
    Array(testLine[firstCollectionLine.lineRange].utf8)
      == Array(rawTestLine.utf8)
  )
  #expect(firstCollectionLine.cap == terminator)
  #expect(collectionLines.count == 1)

  let sequenceLines = await AnySequence(testLine.utf8).internetLines.collect()
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
    .collect()
  #expect(lines == ["Line 1", "Line 2", "Line 3", "Line 4"])
}

/// A demostration with carriage returns.
@Test("Hold back carriage-return productions until the next line break")
func carriageReturnQueuing() async throws {
  let input =
    "Line 1\r\nLine 2\r\u{000B}Line 3\r\u{000C}Line 4\r\rLine 5\rLine 6\r"
  let lines = await AnySequence(input.utf8)
    .internetLines
    .map { String(decoding: $0.line, as: UTF8.self) }
    .collect()
  #expect(
    lines == [
      "Line 1", "Line 2", "", "Line 3", "", "Line 4", "", "Line 5", "Line 6",
    ]
  )
}

/// Confirm that an empty source vends no lines.
@Test("Ensure empty input gives empty output (instead of a single empty line)")
func emptyInputAndOutput() async throws {
  let emptySync = EmptyCollection<UInt8>()
  let emptyAsync = AsyncStream<UInt8> { $0.finish() }
  await #expect(emptySync.internetLines.collect().isEmpty)
  await #expect(AnySequence(emptySync).internetLines.collect().isEmpty)
  await #expect(emptyAsync.internetLines.collect().isEmpty)
}

// MARK: - Helpers

extension AsyncSequence {
  /// Gather all the elements of this asynchronous sequence into a
  /// new synchronous sequence of the given type.
  fileprivate func collect<T: RangeReplaceableCollection<Element>>(
    into type: T.Type
  ) async rethrows -> T {
    return try await reduce(into: T()) { $0.append($1) }
  }

  /// Gather all the elements of this asynchronous sequence into an array.
  fileprivate func collect() async rethrows -> [Element] {
    return try await self.collect(into: Array.self)
  }
}
