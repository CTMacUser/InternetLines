/// `Collection` conformance for `InternetLineTerminator`.
//
// SPDX-FileCopyrightText: © 2026 Daryle Walker (@CTMacUser)
// SPDX-License-Identifier: MIT

extension InternetLineTerminator: RandomAccessCollection {
  public typealias Element = UInt8
  public typealias Index = Int

  public func _copyToContiguousArray() -> ContiguousArray<Element> {
    return switch self {
    case .nothing:
      []
    case .lineFeed:
      [0xA]
    case .lineTabulation:
      [0xB]
    case .formFeed:
      [0xC]
    case .carriageReturn:
      [0xD]
    case .crlf:
      [0xD, 0xA]
    }
  }
  public func _customContainsEquatableElement(_ element: Element) -> Bool? {
    return self._customIndexOfEquatableElement(element).map { $0 != .none }
  }
  public func _customIndexOfEquatableElement(_ element: Element) -> Index?? {
    // I don't know if this is actually more efficient.
    return switch (element, self) {
    case (0xA, .lineFeed), (0xB, .lineTabulation), (0xC, .formFeed),
      (0xD, .carriageReturn), (0xD, .crlf):
      .some(0)
    case (0xA, .crlf):
      .some(1)
    default:
      .some(.none)
    }
  }
  public func _customLastIndexOfEquatableElement(_ element: Element) -> Index?? {
    // Each valid element appears only once in its string.
    return self._customIndexOfEquatableElement(element)
  }

  public var endIndex: Index {
    switch self {
    case .nothing:
      0
    case .lineFeed, .lineTabulation, .formFeed, .carriageReturn:
      1
    case .crlf:
      2
    }
  }
  public var indices: Range<Index> { startIndex..<endIndex }
  public var startIndex: Index { 0 }

  public var count: Int { self.endIndex }
  public var isEmpty: Bool { self == .nothing }

  public func distance(from start: Index, to end: Index) -> Int {
    return end - start
  }

  public func formIndex(after i: inout Index) {
    i += 1
  }
  public func formIndex(before i: inout Index) {
    i -= 1
  }
  public func index(_ i: Index, offsetBy distance: Int) -> Index {
    return i + distance
  }
  public func index(after i: Index) -> Index {
    return i + 1
  }
  public func index(before i: Index) -> Index {
    return i - 1
  }

  public subscript(position: Index) -> Element {
    return switch (self, position) {
    case (.lineFeed, 0), (.crlf, 1):
      0xA
    case (.lineTabulation, 0):
      0xB
    case (.formFeed, 0):
      0xC
    case (.carriageReturn, 0), (.crlf, 0):
      0xD
    default:
      preconditionFailure(
        """
        Index \(position) for \(#function) is out of range \
        \(self.indices) in \(self).
        """
      )
    }
  }

  public func withContiguousStorageIfAvailable<R>(
    _ body: (UnsafeBufferPointer<Element>) throws -> R
  ) rethrows -> R? {
    return try self._copyToContiguousArray().withContiguousStorageIfAvailable(
      body
    )
  }
}
