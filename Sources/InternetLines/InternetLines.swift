/// A stream that splits a collection into lines.
//
// SPDX-FileCopyrightText: © 2026 Daryle Walker (@CTMacUser)
// SPDX-License-Identifier: MIT

// MARK: Line-termination sequences

/// The ASCII character sequence used to terminate a line,
/// following common internet protocols.
public enum InternetLineTerminator: Sendable {
  /// No terminator (end of stream).
  case nothing
  /// Line Feed (LF), `0x0A`.
  case lineFeed
  /// Line Tabulation (VT), `0x0B`.
  ///
  /// Also known as Vertical Tabulation.
  case lineTabulation
  /// Form Feed (FF), `0x0C`.
  case formFeed
  /// Carriage Return (CR), `0x0D`.
  case carriageReturn
  /// Carriage Return followed by Line Feed (CRLF), `0x0D` → `0x0A`.
  case crlf
}

extension InternetLineTerminator: CaseIterable {}

extension InternetLineTerminator: Comparable, Hashable {}

extension InternetLineTerminator: Decodable, Encodable {}

// MARK: - Parsing State

/// Retained data after reading a CR, to be vended in the next loop.
enum LineParsingReserve<Elements: Collection> {
  /// A single byte is stored for the next loop.
  ///
  /// This happens when the next byte after a CR is not LF.
  case byte(value: Elements.Element)
  /// Multiple bytes are stored for the next loop.
  ///
  /// This happens after a carriage-return (CR) is read in.
  /// The line needs to be stored until the next byte is known (LF vs not).
  case line(line: Elements)
}

// MARK: - Line locator

/// The boundaries of a line within a collection of bytes,
/// using common Internet protocols to determine the line-breaking sequences,
/// and a cache of the line terminator found.
///
/// Instances are the elements of a `InternetLineRangeSequence`,
/// which itself is generated from a collection's `internetLineRanges` property.
///
/// For a given location value *l*:
/// - `l.contentRange.upperBound == l.terminatorRange.lowerBound`.
/// - At most one of `l.contentRange` or `l.terminatorRange` is empty.
/// And with a valid collection client *c*:
/// - `c[l.terminatorRange].count == l.terminator.count`.
///
/// - Parameter Index: The `Index` type of the client collection type.
///
/// `InternetLineLocation` specifies where a line starts and ends in its parent collection,
/// as well as the point of partition between the line's content and its line-ending terminator.
///
/// For any parsed line, the following index relationship holds: `lineStart <= partition <= lineEnd`.
public struct InternetLineLocation<Index: Comparable>: Equatable {
  /// The starting index of the line's content in the collection.
  let lineStart: Index
  /// The index that separates the line's content from its line terminator.
  let partition: Index
  /// The past-the-end index of the line's terminator.
  let lineEnd: Index

  /// The line terminator used to end this line.
  public let terminator: InternetLineTerminator

  /// Creates a locator for a parsed line,
  /// with its indices within its collection and the terminator value.
  ///
  /// - Precondition: The distance between `mid` and `end` has to
  ///   be consistent with `terminator.count`,
  ///   and `start ≤ mid ≤ end`.
  ///
  /// - Parameters:
  ///   - start: The index of the first element of the line's content.
  ///   - mid: The index of the first element of the line's terminator.
  ///     This is also the past-the-end point of the line's content.
  ///   - end: The past-the-end point of the line's terminator.
  ///   - terminator: The terminator's logical value used to end the line.
  init(
    startingAt start: Index,
    partitionedAt mid: Index,
    endingPast end: Index,
    cappedWith terminator: InternetLineTerminator
  ) {
    // There's no test for mid/end vs terminator.count because checking that
    // depends on the logic in the corresponding collection instance.
    precondition(start <= mid)
    precondition(mid <= end)

    self.lineStart = start
    self.partition = mid
    self.lineEnd = end
    self.terminator = terminator
  }

  /// The index range covering the content of the line,
  /// excluding the terminator.
  public var contentRange: Range<Index> { self.lineStart..<self.partition }
  /// The index range covering the line's terminator.
  public var terminatorRange: Range<Index> { self.partition..<self.lineEnd }
  /// The index range covering the entire line,
  /// including both its content and its terminator.
  public var lineRange: Range<Index> { self.lineStart..<self.lineEnd }
}

extension InternetLineLocation: Sendable where Index: Sendable {}
extension InternetLineLocation: Hashable where Index: Hashable {}
extension InternetLineLocation: Decodable where Index: Decodable {}
extension InternetLineLocation: Encodable where Index: Encodable {}

extension InternetLineLocation: CustomDebugStringConvertible {
  public var debugDescription: String {
    """
    \(String(describing: Self.self))\
    (\(self.lineStart)..<\(self.partition)..<\(self.lineEnd); \
    \(self.terminator))
    """
  }
}

// MARK: - Featured properties

extension Sequence where Element == UInt8 {
  /// Provides a sequence that parses out each line within this sequence.
  ///
  /// A line is expressed as its bytes before the terminator,
  /// then what the line's terminating byte sequence is.
  public var internetLines: InternetLineSequence<Self, [Element]> {
    .init(self)
  }
}

extension Collection where Element == UInt8 {
  /// Provides a sequence that reveals each line's location within this
  /// collection, synchronously.
  ///
  /// The line is expressed as the range of its bytes before the terminator,
  /// then what the line's terminating byte sequence is.
  public var internetLineRanges: InternetLineRangeSequence<Self> {
    .init(of: self)
  }
}

extension AsyncSequence where Element == UInt8 {
  /// Provides an asynchronous sequence that parses out each line within this
  /// sequence.
  ///
  /// A line is expressed as its bytes before the terminator,
  /// then what the line's terminating byte sequence is.
  public var internetLines: AsyncInternetLineSequence<Self, [UInt8]> {
    .init(self)
  }
}
