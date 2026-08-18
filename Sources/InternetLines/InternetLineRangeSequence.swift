/// A sequence that reports the bounds of each line within a collection of
/// bytes.
//
// SPDX-FileCopyrightText: © 2026 Daryle Walker (@CTMacUser)
// SPDX-License-Identifier: MIT

/// A sequence that produces the index ranges of each line within a
/// collection of bytes,
/// with line breaking determined with byte values commonly found in
/// Internet protocol standards.
///
/// Instances are obtained by using the extension `internetLines` computed
/// property of the targeted collection.
///
/// Each produced element is a tuple containing:
/// - `lineRange`: the half-open range in the base collection that covers the
///   bytes of the line, excluding its terminator
/// - `cap`: the detected line terminator as `InternetLineTerminator`
///
/// Recognized terminators are the line feed (`0x0A`),
/// vertical tab (`0x0B`),
/// form feed (`0x0C`),
/// carriage return (`0x0D`),
/// and the two-byte sequence of a carriage return followed by a line feed.
/// If the collection ends without a terminator,
/// the `.nothing` placeholder is used.
///
/// For instance, this will print each non-empty line, with line numbers:
///
/// ```swift
/// let data = Data("Hello\r\nWorld\n\rNoTerminator".utf8)
/// for (lineNumber, (range, cap)) in data.internetLines.enumerated()
/// where !range.isEmpty {
///   let line = String(data: data[range], encoding: .macOSRoman)
///   print("\(lineNumber): \(String(reflecting: line!)) [terminator: \(cap)]")
/// }
/// /*
///  Prints:
///     0: "Hello" [terminator: crlf]
///     1: "World" [terminator: lineFeed]
///     3: "NoTerminator" [terminator: nothing]
///  */
/// ```
///
/// - Parameter Base: The underlying collection of bytes to be parsed.
public struct InternetLineRangeSequence<Base: Collection<UInt8>>:
  LazySequenceProtocol
{
  /// The underlying collection of bytes.
  let base: Base

  /// Creates a range-generating line-parsing sequence wrapping the given
  /// collection of bytes.
  ///
  /// - Parameter base: The collection of bytes to parse.
  init(of base: Base) {
    self.base = base
  }

  public struct Iterator: IteratorProtocol {
    /// The underlying collection of bytes.
    let base: Base
    /// A flag indicating whether the iterator has finished traversing the
    /// collection.
    var hasFinished = false
    /// The index from which the next line search will begin.
    var searchStart: Base.Index

    /// Creates a range-generating line-parsing iterator wrapping the given
    /// collection of bytes.
    ///
    /// - Parameter base: The collection of bytes to parse.
    init(of base: Base) {
      self.base = base
      self.searchStart = base.startIndex
    }

    public mutating func next() -> (
      lineRange: Range<Base.Index>, cap: InternetLineTerminator
    )? {
      guard !hasFinished else { return nil }
      guard
        let terminatorStart = self.base[searchStart...].firstIndex(where: {
          0x0A...0x0D ~= $0
        })
      else {
        hasFinished = true
        if searchStart < self.base.endIndex {
          return (searchStart..<self.base.endIndex, .nothing)
        } else {
          return nil
        }
      }

      let afterTerminator = self.base.index(after: terminatorStart)
      let terminator: InternetLineTerminator
      var nextStart = afterTerminator
      switch self.base[terminatorStart] {
      case 0x0A:
        terminator = .lineFeed
      case 0x0B:
        terminator = .lineTabulation
      case 0x0C:
        terminator = .formFeed
      case 0x0D:
        if afterTerminator < self.base.endIndex,
          self.base[afterTerminator] == 0x0A
        {
          terminator = .crlf
          self.base.formIndex(after: &nextStart)
        } else {
          terminator = .carriageReturn
        }
      default:
        preconditionFailure("This should not be reachable")
      }
      defer { searchStart = nextStart }

      return (searchStart..<terminatorStart, terminator)
    }
  }

  public func makeIterator() -> Iterator {
    return .init(of: self.base)
  }
  public var underestimatedCount: Int { base.isEmpty ? 0 : 1 }
}
