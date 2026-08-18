/// A stream that splits a collection into lines.
//
// SPDX-FileCopyrightText: © 2026 Daryle Walker (@CTMacUser)
// SPDX-License-Identifier: MIT

// MARK: Line-termination sequences

/// The ASCII character sequence used to terminate a line,
/// following common internet protocols.
public enum InternetLineTerminator: Sendable {
  /// No terminator (end of file).
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
  /// Carriage Return and Line Feed (CRLF), `0x0D` then `0x0A`.
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
  public var internetLines:
    AnySequence<(lineRange: Range<Index>, cap: InternetLineTerminator)>
  {
    return AnySequence {
      var latest = self.startIndex
      var hasFinished = false

      return AnyIterator<(lineRange: Range<Index>, cap: InternetLineTerminator)>
      {
        guard !hasFinished else { return nil }
        guard
          let terminatorStart = self[latest...].firstIndex(where: {
            0x0A...0x0D ~= $0
          })
        else {
          hasFinished = true
          if latest < self.endIndex {
            return (latest..<self.endIndex, .nothing)
          } else {
            return nil
          }
        }

        let afterTerminator = self.index(after: terminatorStart)
        let terminator: InternetLineTerminator
        var nextStart = afterTerminator
        switch self[terminatorStart] {
        case 0x0A:
          terminator = .lineFeed
        case 0x0B:
          terminator = .lineTabulation
        case 0x0C:
          terminator = .formFeed
        case 0x0D:
          if afterTerminator < self.endIndex, self[afterTerminator] == 0x0A {
            terminator = .crlf
            self.formIndex(after: &nextStart)
          } else {
            terminator = .carriageReturn
          }
        default:
          preconditionFailure("This should not be reachable")
        }
        defer { latest = nextStart }

        return (latest..<terminatorStart, terminator)
      }
    }
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
