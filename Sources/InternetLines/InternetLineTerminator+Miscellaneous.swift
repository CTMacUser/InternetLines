/// Other conformances for `InternetLineTerminator`.
//
// SPDX-FileCopyrightText: © 2026 Daryle Walker (@CTMacUser)
// SPDX-License-Identifier: MIT

extension InternetLineTerminator: LosslessStringConvertible {
  public init?(_ description: String) {
    guard let cap = Self.nameStringToTerminator[description] else { return nil }

    self = cap
  }

  public var description: String {
    // I don't know if there's any way to automate this.
    // Any APIs you'd think cover this all assume that this property wasn't
    // overridden. Whoops!
    switch self {
    case .nothing:
      "nothing"
    case .lineFeed:
      "lineFeed"
    case .lineTabulation:
      "lineTabulation"
    case .formFeed:
      "formFeed"
    case .carriageReturn:
      "carriageReturn"
    case .crlf:
      "crlf"
    }
  }

  /// Look-up terminator name strings to `InternetLineTerminator` values.
  private static let nameStringToTerminator = Dictionary(
    uniqueKeysWithValues: zip(
      InternetLineTerminator.allCases.map(\.description),
      InternetLineTerminator.allCases
    )
  )
}

extension InternetLineTerminator: RawRepresentable {
  public var rawValue: String {
    String(decoding: self._copyToContiguousArray(), as: UTF8.self)
  }

  public init?(rawValue: String) {
    guard let cap = Self.rawStringToTerminator[rawValue] else { return nil }

    self = cap
  }

  /// Look-up raw terminator strings to `InternetLineTerminator` values.
  private static let rawStringToTerminator = Dictionary(
    uniqueKeysWithValues: zip(
      InternetLineTerminator.allCases.map(\.rawValue),
      InternetLineTerminator.allCases
    )
  )
}
