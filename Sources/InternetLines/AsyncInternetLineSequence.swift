/// An asynchronous sequence that splits another into lines.
//
// SPDX-FileCopyrightText: © 2026 Daryle Walker (@CTMacUser)
// SPDX-License-Identifier: MIT

/// An asynchronous iterator that partitions bytes from another iterator into
/// individual lines.
///
/// This iterator monitors an underlying `AsyncIteratorProtocol` for bytes that
/// match internet-standard line terminators (such as CRLF, CR, or LF),
/// splitting the stream accordingly.
///
/// - Parameters:
///   - Base: The underlying `AsyncIteratorProtocol` that provides the bytes to
///     be parsed.
///   - Segment: The `RangeReplaceableCollection` type used to buffer the
///     bytes of each line.
///
/// Each call to ``next()`` returns an optional tuple containing the
/// line bytes (as a `Segment`) and the `InternetLineTerminator` that
/// concluded the line.
public struct AsyncInternetLineIterator<
  Base: AsyncIteratorProtocol,
  Segment: RangeReplaceableCollection<UInt8>
>: AsyncIteratorProtocol where Base.Element == UInt8 {

  @available(macOS 15.0, *)
  public typealias Failure = Base.Failure

  /// Indicates if the base iterator has been exhausted.
  private var hasBaseFinished: Bool? = false
  /// The underlying asynchronous iterator.
  private var base: Base
  /// The state machine used to identify line terminators.
  private var parser = SplitFinder()
  /// The buffer used to accumulate bytes for the current line.
  private var lineBuffer = Segment()

  /// Creates a new iterator wrapping the provided base iterator.
  init(_ base: Base) {
    self.base = base
    self.lineBuffer.reserveCapacity(998)
  }

  public mutating func next() async throws -> (
    line: Segment, terminator: InternetLineTerminator
  )? {
    guard !Task.isCancelled else { return nil }
    guard hasBaseFinished != true else { return nil }

    while let byte = try await base.next() {
      let processingAction = parser(processing: byte)

      if processingAction.doCrBreak {
        let line = lineBuffer
        lineBuffer.removeAll(keepingCapacity: true)

        if let retainedByte = processingAction.retention {
          switch retainedByte {
          case .cr:
            break
          case .normal:
            lineBuffer.append(byte)
          }
        }
        return (line, .carriageReturn)
      }

      if let cap = processingAction.primaryBreak {
        let line = lineBuffer
        lineBuffer.removeAll(keepingCapacity: true)
        return (line, cap)
      }

      if let retainedByte = processingAction.retention {
        switch retainedByte {
        case .cr:
          break
        case .normal:
          lineBuffer.append(byte)
        }
      } else {
        lineBuffer.append(byte)
      }
    }
    hasBaseFinished = true

    if parser.previousWasCR {
      let line = lineBuffer
      lineBuffer.removeAll()
      return (line, .carriageReturn)
    }

    if !lineBuffer.isEmpty {
      let line = lineBuffer
      lineBuffer.removeAll()
      return (line, .nothing)
    }

    return nil
  }
}

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
  /// The underlying asynchronous sequence.
  private let base: Base

  /// Creates a new sequence wrapping the provided base sequence.
  init(base: Base) {
    self.base = base
  }

  public func makeAsyncIterator() -> AsyncInternetLineIterator<
    Base.AsyncIterator, Segment
  > {
    return .init(base.makeAsyncIterator())
  }
}

extension AsyncSequence where Element == UInt8 {
  /// Provides a sequence that parses out each line within this sequence.
  ///
  /// A line is expressed as its bytes before the terminator,
  /// then what the line's terminating byte sequence is.
  public var internetLines: AsyncInternetLineSequence<Self, [UInt8]> {
    .init(base: self)
  }
}
