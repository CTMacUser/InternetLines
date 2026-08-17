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

extension Collection where Element == UInt8, Index: Sendable {
  /// Provides a stream that parses out each line within this sequence.
  ///
  /// The line is expressed as the range of its bytes before the terminator,
  /// then what the line's terminating byte sequence is.
  public var internetLines:
    AsyncStream<(lineRange: Range<Index>, cap: InternetLineTerminator)>
  {
    AsyncStream { continuation in
      var parser = SplitFinder()
      var start = self.startIndex
      var lastCrIndex: Index?
      for i in self.indices {
        guard !Task.isCancelled else { break }

        let processingAction = parser(processing: self[i])
        if processingAction.doCrBreak {
          let yield = continuation.yield(
            (start..<lastCrIndex!, .carriageReturn)
          )
          assert(self.distance(from: lastCrIndex!, to: i) == 1)
          start = i
          lastCrIndex = nil
          if case .terminated = yield {
            break
          }
        }
        if let cap = processingAction.primaryBreak {
          let capStart = lastCrIndex ?? i
          let yield = continuation.yield((start..<capStart, cap))
          assert(0...1 ~= self.distance(from: capStart, to: i))
          start = self.index(after: i)
          lastCrIndex = nil
          if case .terminated = yield {
            break
          }
        }
        if let retainedByte = processingAction.retention {
          switch retainedByte {
          case .cr:
            lastCrIndex = i
          case .normal:
            break
          }
        }
      }

      if let lastCrIndex {
        continuation.yield((start..<lastCrIndex, .carriageReturn))
        start = self.index(after: lastCrIndex)
      }
      if start < self.endIndex {
        continuation.yield((start..<self.endIndex, .nothing))
      }
      continuation.finish()
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

// MARK: - Implementation

/// State machine identifying line-termination sequences within the stream of
/// given bytes.
struct SplitFinder {
  /// Creates a line-splitting state machine.
  init() {
    // Nothing to do, but this is here for clarity.
  }

  /// Flag indicating if the last processed byte was a Carriage Return (`0xD`).
  private(set) var previousWasCR = false

  /// How the client should proceed after processing a byte.
  enum Action {
    /// Which policy to use after reading a byte that won't (immediately)
    /// break a line.
    enum Retention {
      /// Signals that a Carriage Return (`0x0D`) was encountered and should be
      /// tracked by the state machine.
      case cr
      /// Signals that the byte is a standard data byte (not a terminator) and
      /// should be included in the current line buffer.
      case normal
    }

    /// Signals a line break triggered by a standard terminator
    /// (*e.g.*, `LF`, `VT`, `FF`).
    case breakWith(terminator: InternetLineTerminator)
    /// Signals a line break triggered by a character that followed a `CR`
    /// (which itself terminated the previous line).
    case breakWithCrThen(terminator: InternetLineTerminator)
    /// Indicates that the previous `CR` should have broken the line,
    /// and the current non-terminating character is the start of a new line.
    case breakWithCrThenRetain
    /// Indicates that a `CR` occurred, following a previous `CR`.
    /// The first `CR` breaks the line, the second `CR` is retained for
    /// the next potential line break.
    case breakWithCrThenRetainCr
    /// A single `CR` has been encountered.
    /// It is held, waiting to see if the *next* byte is `LF` (to form `CRLF`)
    /// or something else (which would finalize the line break at the `CR`).
    case retainCr
    /// The character is not a terminator and does not follow a `CR`.
    /// It is appended to the current line.
    case retain

    /// Whether an enqueued line ending with a CR needs to be produced before
    /// handling the current byte.
    var doCrBreak: Bool {
      switch self {
      case .breakWithCrThen, .breakWithCrThenRetain, .breakWithCrThenRetainCr:
        true
      default:
        false
      }
    }
    /// Whether the queued bytes need to be immediately produced as a line with
    /// the returned line-terminating sequence.
    var primaryBreak: InternetLineTerminator? {
      switch self {
      case .breakWith(terminator: let cap),
        .breakWithCrThen(terminator: let cap):
        cap
      default:
        nil
      }
    }
    /// How processed byte should be remembered for a later line production,
    /// if it should.
    var retention: Retention? {
      switch self {
      case .breakWithCrThenRetainCr, .retainCr:
        .cr
      case .breakWithCrThenRetain, .retain:
        .normal
      default:
        nil
      }
    }
  }

  /// Considers the given byte with the current state to
  /// return the next action the line-reading client should do.
  mutating func callAsFunction(processing byte: UInt8)
    -> Action
  {
    defer { previousWasCR = byte == 0xD }

    return switch (byte, previousWasCR) {
    case (0xA, true):
      .breakWith(terminator: .crlf)
    case (0xA, false):
      .breakWith(terminator: .lineFeed)
    case (0xB, true):
      .breakWithCrThen(terminator: .lineTabulation)
    case (0xB, false):
      .breakWith(terminator: .lineTabulation)
    case (0xC, true):
      .breakWithCrThen(terminator: .formFeed)
    case (0xC, false):
      .breakWith(terminator: .formFeed)
    case (0xD, true):
      .breakWithCrThenRetainCr
    case (0xD, false):
      .retainCr
    case (_, true):
      .breakWithCrThenRetain
    case (_, false):
      .retain
    }
  }
}
