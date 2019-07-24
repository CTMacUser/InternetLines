//
//  LineTerminatorLocations.swift
//  InternetLines
//
//  Created by Daryle Walker on 6/15/19.
//

import OptionalTraversal


// MARK: - Line-Breaking Sequence Targets

/// Options for which line-breaking sequences to target while searching.
public struct LineTerminatorSearchTargets: OptionSet, Hashable {

    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    /// Offsets for each option bit.
    private enum OptionOffset: Int {
        case lf, crlf, crcrlf, cr
    }

    /// Searches will target isolated line feeds (LF).
    public static let lf = LineTerminatorSearchTargets(rawValue: 1 << OptionOffset.lf.rawValue)
    /// Searches will target CR-LF sequences.
    public static let crlf = LineTerminatorSearchTargets(rawValue: 1 << OptionOffset.crlf.rawValue)
    /// Searches will target CR-CR-LF sequences.  These aren't official, they
    /// can only occur when the user manually writes out a CR-LF on a Windows
    /// platform in C while already in text mode, which converts logical LF
    /// occurances to CR-LF in the binary stream.
    public static let crcrlf = LineTerminatorSearchTargets(rawValue: 1 << OptionOffset.crcrlf.rawValue)
    /// Searches will target isolated carriage returns (CR).
    public static let cr = LineTerminatorSearchTargets(rawValue: 1 << OptionOffset.cr.rawValue)

    /// What searches in Internet-sourced text is supposed to look for.
    public static let strict: LineTerminatorSearchTargets = [.crlf]
    /// What searches should practically look for.
    public static let standard: LineTerminatorSearchTargets = [.lf, .crlf, .cr]
    /// What to search for if a source can be from a Windows conversion.
    public static let paranoid: LineTerminatorSearchTargets = [.lf, .crlf, .crcrlf, .cr]

    /// All search targets.
    public static let all = LineTerminatorSearchTargets(rawValue: RawValue.max)

}

// MARK: - Line-Breaking Sequence Locators

/// An iterator over locations within a given collection of where its line-
/// breaking sequences are.
struct LineTerminatorLocationIterator<Base: Collection> {

    /// The remaining sub-collection to search.
    var collection: Base.SubSequence
    /// Which line-breaking sequences to search for.
    let targets: LineTerminatorSearchTargets
    /// The closure to identify carriage returns.
    let isCr: (Base.Element) -> Bool
    /// The closure to identify line feeds.
    let isLf: (Base.Element) -> Bool

}

extension LineTerminatorLocationIterator: IteratorProtocol {

    mutating func next() -> Range<Base.Index>? {
        var result: Range<Base.Index>?
        var first = collection.startingIndex
        var second = first.flatMap { collection.elementIndex(after: $0) }
        var third = second.flatMap { collection.elementIndex(after: $0) }
        while let firstIndex = first, result == nil {
            defer {
                first = second
                second = third
                third = third.flatMap { collection.elementIndex(after: $0) }
            }

            let secondValue = second.map { collection[$0] }
            let thirdValue = third.map { collection[$0] }
            let firstIsCr = isCr(collection[firstIndex])
            let firstIsLf = isLf(collection[firstIndex])
            let secondIsCr = secondValue.map { isCr($0) }
            let secondIsLf = secondValue.map { isLf($0) }
            let thirdIsLf = thirdValue.map { isLf($0) }
            switch (firstIsCr, firstIsLf, secondIsCr, secondIsLf, thirdIsLf) {
            case (true, _, true, _, true) where targets.contains(.crcrlf):
                result = firstIndex..<collection.index(after: third!)
            case (true, _, _, true, _) where targets.contains(.crlf):
                result = firstIndex..<collection.index(after: second!)
                case (true, _, _, _, _) where targets.contains(.cr),
                     (_, true, _, _, _) where targets.contains(.lf):
                result = firstIndex..<collection.index(after: firstIndex)
            default:
                break
            }
        }
        collection = collection[(result?.upperBound ?? collection.endIndex)...]
        return result
    }

}

// MARK: Sequence

/// A sequence over locations within a given collection of where its line-
/// breaking sequences are.
struct LineTerminatorLocations<Base: Collection> {

    /// The collection to search.
    let base: Base
    /// Which line-breaking sequences to search for.
    let targets: LineTerminatorSearchTargets
    /// The closure to identify carriage returns.
    let isCr: (Base.Element) -> Bool
    /// The closure to identify line feeds.
    let isLf: (Base.Element) -> Bool

}

extension LineTerminatorLocations: Sequence {

    __consuming func makeIterator() -> LineTerminatorLocationIterator<Base> {
        return LineTerminatorLocationIterator(collection: base[...], targets: targets, isCr: isCr, isLf: isLf)
    }

    var underestimatedCount: Int {
        return base.prefix(3).lineTerminatorLocations(considering: targets, isCarriageReturn: isCr, isLineFeed: isLf).first == nil ? 0 : 1
    }

}

// MARK: Collection

extension LineTerminatorLocations: Collection {

    struct Index: Comparable {
        /// Where the line-breaking sequence is located in `base`.
        let indices: Range<Base.Index>

        static func < (lhs: Index, rhs: Index) -> Bool {
            return lhs.indices.lowerBound < rhs.indices.lowerBound
        }
    }

    // Note: This runs at O(n)!
    var startIndex: Index {
        var iterator = makeIterator()
        return iterator.next().map { Index(indices: $0) } ?? endIndex
    }
    var endIndex: Index {
        return Index(indices: base.endIndex..<base.endIndex)
    }

    subscript(position: Index) -> Range<Base.Index> {
        precondition(!position.indices.isEmpty)

        return position.indices
    }

    func index(after i: Index) -> Index {
        var iterator = LineTerminatorLocationIterator<Base>(collection: base[i.indices.upperBound...], targets: targets, isCr: isCr, isLf: isLf)
        return iterator.next().map { Index(indices: $0) } ?? endIndex
    }

}

extension LineTerminatorLocations.Index: Hashable where Base.Index: Hashable {}

// MARK: Bi-directional Collection

extension LineTerminatorLocations: BidirectionalCollection where Base: BidirectionalCollection {

    func index(before i: Index) -> Index {
        // Same as the iterator's next(), but backwards
        var result: Range<Base.Index>?
        var third = base.elementIndex(before: i.indices.lowerBound)
        var second = third.flatMap { base.elementIndex(before: $0) }
        var first = second.flatMap { base.elementIndex(before: $0) }
        while let thirdIndex = third, result == nil {
            defer {
                third = second
                second = first
                first = first.flatMap { base.elementIndex(before: $0) }
            }

            let firstValue = first.map { base[$0] }
            let secondValue = second.map { base[$0] }
            let firstIsCr = firstValue.map { isCr($0) }
            let secondIsCr = secondValue.map { isCr($0) }
            let thirdIsCr = isCr(base[thirdIndex])
            let thirdIsLf = isLf(base[thirdIndex])
            switch (firstIsCr, secondIsCr, thirdIsCr, thirdIsLf) {
            case (true, true, _, true) where targets.contains(.crcrlf):
                result = first! ..< base.index(after: thirdIndex)
            case (_, true, _, true) where targets.contains(.crlf):
                result = second! ..< base.index(after: thirdIndex)
            case (_, _, true, _) where targets.contains(.cr),
                 (_, _, _, true) where targets.contains(.lf):
                result = thirdIndex..<base.index(after: thirdIndex)
            default:
                break
            }
        }
        return Index(indices: result!)
    }

}

// MARK: Adaptor Generators

extension Collection {

    /// Returns a collection of this collection's line-terminator sequence
    /// locations, using the given predicates to identify line-breaking element
    /// values.
    ///
    /// - Precondition: No element value can satisfy both `isCarriageReturn` and
    ///   `isLineFeed` simultaneously.
    ///
    /// - Parameter targets: The line-terminating subsequences to accept.
    /// - Parameter isCarriageReturn: A predicate that identifies a given
    ///   element value as a carriage return.
    /// - Parameter isLineFeed: A predicate that identifies a given element
    ///   value as a line feed.
    ///
    /// - Returns: A collection adaptor vending the locations (as index ranges)
    ///   of each qualifying line-terminating subsequence.
    func lineTerminatorLocations(considering targets: LineTerminatorSearchTargets, isCarriageReturn: @escaping (Element) -> Bool, isLineFeed: @escaping (Element) -> Bool) -> LineTerminatorLocations<Self> {
        return LineTerminatorLocations(base: self, targets: targets, isCr: isCarriageReturn, isLf: isLineFeed)
    }

}

extension Collection where Element: Equatable & InternetLineBreakerValues {

    /// Returns a collection of this collection line-terminator sequence locations.
    func lineTerminatorLocations(considering targets: LineTerminatorSearchTargets) -> LineTerminatorLocations<Self> {
        return lineTerminatorLocations(considering: targets, isCarriageReturn: { $0 == Element.crValue }, isLineFeed: { $0 == Element.lfValue })
    }

}
