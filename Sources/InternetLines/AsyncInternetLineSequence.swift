/// An asynchronous sequence that splits another into lines.
//
// SPDX-FileCopyrightText: © 2026 Daryle Walker (@CTMacUser)
// SPDX-License-Identifier: MIT

/// An asynchronous sequence that parses an underlying sequence of bytes into
/// lines.
///
/// This sequence wraps a base `AsyncSequence` of bytes, transforming it into
/// a sequence of lines terminated by internet-standard sequences
/// (e.g., CRLF, CR, or LF).
///
/// - Parameters:
///   - Base: The underlying `AsyncSequence` that produces the bytes to
///     be parsed.
///   - Segment: The `RangeReplaceableCollection` type used to buffer the
///     bytes of each line.
///
/// The resulting sequence yields lines as tuples of
/// `(Segment, InternetLineTerminator)`.
public struct AsyncInternetLineSequence<
  Base: AsyncSequence,
  Segment: RangeReplaceableCollection<UInt8>
>: AsyncSequence where Base.Element == UInt8 {
  public struct AsyncIterator: AsyncIteratorProtocol {
    var base: Base.AsyncIterator
    var hasFinished = false
    var reserve: LineParsingReserve<Segment>?

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

  let base: Base

  init(_ base: Base, vending type: Segment.Type = Segment.self) {
    self.base = base
  }

  public func makeAsyncIterator() -> AsyncIterator {
    return .init(self.base.makeAsyncIterator())
  }
}
