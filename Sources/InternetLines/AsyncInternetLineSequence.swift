/// An asynchronous sequence that splits another into lines.
//
// SPDX-FileCopyrightText: © 2026 Daryle Walker (@CTMacUser)
// SPDX-License-Identifier: MIT

/// An asynchronous sequence that parses an underlying sequence of bytes into
/// lines,
/// with line breaking determined with byte values commonly found in
/// Internet protocol standards.
///
/// Instances are obtained by using the extension `internetLines` computed
/// property of the targeted sequence.
///
/// Each produced element is a tuple containing:
/// - `line`: the content
/// - `cap`: the detected line terminator as `InternetLineTerminator`
///
/// Recognized terminators are the line feed (`0x0A`),
/// vertical tab (`0x0B`),
/// form feed (`0x0C`),
/// carriage return (`0x0D`),
/// and the two-byte sequence of a carriage return followed by a line feed.
/// If the sequence ends without a terminator,
/// the `.nothing` placeholder is used.
///
/// For instance, this will print each non-empty line:
///
/// ```swift
/// import Foundation
///
/// let stream = AsyncStream { continuation in
///   let data = Data("Hello\r\nWorld\n\rNoTerminator".utf8)
///   for byte in data {
///     continuation.yield(byte)
///   }
///   continuation.finish()
/// }
/// for try await (lineContents, cap) in stream.internetLines
/// where !lineContents.isEmpty {
///   let line = String(bytes: lineContents, encoding: .macOSRoman)
///   print("\(String(reflecting: line!)) [terminator: \(cap)]")
/// }
/// /*
///  Prints:
///     "Hello" [terminator: crlf]
///     "World" [terminator: lineFeed]
///     "NoTerminator" [terminator: nothing]
///  */
/// ```
///
/// - Parameter Base: The underlying collection of bytes to be parsed.
/// - Parameter Segment: The collection type used to store a line's content.
public struct AsyncInternetLineSequence<
  Base: AsyncSequence,
  Segment: RangeReplaceableCollection<UInt8>
>: AsyncSequence where Base.Element == UInt8 {
  public struct AsyncIterator: AsyncIteratorProtocol {
    /// The wrapped iterator.
    var base: Base.AsyncIterator
    /// Flag when the source iterator is exhausted.
    var hasFinished = false
    /// Saves any excess data to the next loop call.
    ///
    /// Happens when a CR is read,
    /// since it won't be until the following loop if a CRLF line or
    /// a CR line will be produced.
    /// Any remainder will be produced in the next loop.
    var reserve: LineParsingReserve<Segment>?

    /// Creates a line-parsing iterator wrapping the given iterator of bytes.
    init(_ base: Base.AsyncIterator) {
      self.base = base
    }

    public mutating func next() async throws -> (
      line: Segment, cap: InternetLineTerminator
    )? {
      guard !self.hasFinished, !Task.isCancelled else { return nil }

      var buffer = Segment()
      switch self.reserve {
      case .line(let line):
        let following = try await self.base.next()
        guard case .some(0x0A) = following else {
          self.reserve = following.map { .byte(value: $0) }
          return (line, .carriageReturn)
        }

        self.reserve = nil
        return (line, .crlf)
      case .byte(let byte):
        guard 0x0A...0x0D ~= byte else {
          buffer.append(byte)
          fallthrough
        }

        switch byte {
        case 0x0A:
          return (.init(), .lineFeed)
        case 0x0B:
          return (.init(), .lineTabulation)
        case 0x0C:
          return (.init(), .formFeed)
        case 0x0D:
          self.reserve = .line(line: .init())
          return try await self.next()
        default:
          preconditionFailure("The `guard` above should've gotten this")
        }
      case nil:
        while let nextByte = try await self.base.next() {
          switch nextByte {
          case 0x0A:
            return (buffer, .lineFeed)
          case 0x0B:
            return (buffer, .lineTabulation)
          case 0x0C:
            return (buffer, .formFeed)
          case 0x0D:
            self.reserve = .line(line: buffer)
            return try await self.next()
          default:
            buffer.append(nextByte)
          }
        }

        self.hasFinished = true
        return if buffer.isEmpty {
          nil
        } else {
          (buffer, .nothing)
        }
      }
    }
  }

  /// The wrapped sequence.
  let base: Base

  /// Creates a line-parsing sequence wrapping the given sequence of bytes,
  /// copying line data into instances of the given collection type.
  init(_ base: Base, vending type: Segment.Type = Segment.self) {
    self.base = base
  }

  public func makeAsyncIterator() -> AsyncIterator {
    return .init(self.base.makeAsyncIterator())
  }
}
