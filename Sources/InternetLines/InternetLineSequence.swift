/// A sequence that splits a sequence of bytes into lines.
//
// SPDX-FileCopyrightText: © 2026 Daryle Walker (@CTMacUser)
// SPDX-License-Identifier: MIT

/// A synchronous sequence that parses an underlying sequence of bytes into
/// lines.
///
/// This sequence wraps a base `Sequence` of bytes, transforming it into
/// a sequence of lines terminated by internet-standard sequences
/// (e.g., CRLF, CR, or LF).
///
/// - Parameters:
///   - Base: The underlying `Sequence` that produces the bytes to
///     be parsed.
///   - Segment: The `RangeReplaceableCollection` type used to buffer the
///     bytes of each line.
///
/// The resulting sequence yields lines as tuples of
/// `(Segment, InternetLineTerminator)`.
public struct InternetLineSequence<
  Base: Sequence<UInt8>,
  Segment: RangeReplaceableCollection<UInt8>
>: LazySequenceProtocol {
  public struct Iterator: IteratorProtocol {
    /// The wrapped iterator.
    var base: Base.Iterator
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
    init(_ base: Base.Iterator) {
      self.base = base
    }

    public mutating func next() -> (line: Segment, cap: InternetLineTerminator)?
    {
      guard !self.hasFinished else { return nil }

      var buffer = Segment()
      switch self.reserve {
      case .line(let line):
        let following = self.base.next()
        guard case .some(0x0A) = following else {
          self.reserve = following.map { .byte(value: $0) }
          return (line, .carriageReturn)
        }

        self.reserve = nil
        return (line, .crlf)
      case .byte(let byte):
        self.reserve = nil
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
          return self.next()
        default:
          preconditionFailure("The `guard` above should've gotten this")
        }
      case nil:
        while let nextByte = self.base.next() {
          switch nextByte {
          case 0x0A:
            return (buffer, .lineFeed)
          case 0x0B:
            return (buffer, .lineTabulation)
          case 0x0C:
            return (buffer, .formFeed)
          case 0x0D:
            self.reserve = .line(line: buffer)
            return self.next()
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

  public func makeIterator() -> Iterator {
    return .init(self.base.makeIterator())
  }
  public var underestimatedCount: Int { self.base.underestimatedCount.signum() }
}
