//
//  LineLocations.swift
//  InternetLines
//
//  Created by Daryle Walker on 7/24/19.
//

import OptionalTraversal


// MARK: Line-locating Iterator

/// An iterator over locations within a given collection that divide it into
/// lines.
///
/// Which line-breaking subsequences are used is determined by a given set of
/// targets.  All are common combinations of carriage-returns and line-feeds.
/// The testing of element values against a CR or LF is performed by the given
/// closures.
///
/// The vended elements are a tuple of collection-index values bracketing a
/// line.  The first returned property is the start of the line, the second is
/// the border between the line's primary data and the terminator, and the third
/// is the end of the line.  At most one section of a vended return is empty.
/// (If both were empty, then the line had no data.)
public struct LineLocationIterator<Base: Collection> {

    /// The iterator for finding line terminators.
    var inner: LineTerminatorLocationIterator<Base>

}

extension LineLocationIterator: IteratorProtocol {

    public mutating func next() -> (start: Base.Index, border: Base.Index, end: Base.Index)? {
        // An empty collection definitely has no more lines.
        guard let start = inner.collection.startingIndex else { return nil }

        // No terminator means the whole collection is the last line.
        guard let terminatorLocation = inner.next() else {
            let end = inner.collection.endIndex
            return (start: start, border: end, end: end)
        }

        return (start: start, border: terminatorLocation.lowerBound, end: terminatorLocation.upperBound)
    }

}

// MARK: - Line-locating Sequence

/// A sequence over locations within a given collection that divide it into
/// lines.
///
/// Which line-breaking subsequences are used is determined by a given set of
/// targets.  All are common combinations of carriage-returns and line-feeds.
/// The testing of element values against a CR or LF is performed by the given
/// closures.
///
/// The vended elements are a tuple of collection-index values bracketing a
/// line.  The first returned property is the start of the line, the second is
/// the border between the line's primary data and the terminator, and the third
/// is the end of the line.  At most one section of a vended return is empty.
/// (If both were empty, then the line had no data.)
public struct LineLocations<Base: Collection> {

    /// The sequence/collection for finding line terminators.
    var inner: LineTerminatorLocations<Base>

}

extension LineLocations: Sequence {

    public __consuming func makeIterator() -> LineLocationIterator<Base> {
        return LineLocationIterator(inner: inner.makeIterator())
    }

    public var underestimatedCount: Int {
        return inner.base.isEmpty ? 0 : 1
    }

}

// MARK: Collection

extension LineLocations: Collection {

    public struct Index: Comparable {
        /// Where the line starts in `base`.
        let start: Base.Index
        /// Where the line terminates in `base`.
        let terminator: LineTerminatorLocations<Base>.Index

        public static func < (lhs: Index, rhs: Index) -> Bool {
            return lhs.start < rhs.start
        }
    }

    // Note: This runs at O(n)!
    public var startIndex: Index {
        return Index(start: inner.base.startIndex, terminator: inner.startIndex)
    }
    public var endIndex: Index {
        return Index(start: inner.base.endIndex, terminator: inner.endIndex)
    }

    public subscript(position: Index) -> (start: Base.Index, border: Base.Index, end: Base.Index) {
        let s = position.start, b = position.terminator.indices.lowerBound, e = position.terminator.indices.upperBound
        precondition(s != b || b != e)

        return (start: s, border: b, end: e)
    }

    public func index(after i: Index) -> Index {
        let nextInner = inner.index(after: i.terminator)
        return Index(start: i.terminator.indices.upperBound, terminator: nextInner)
    }

}

extension LineLocations.Index: Hashable where Base.Index: Hashable {}

// MARK: BidirectionalCollection

extension LineLocations: BidirectionalCollection where Base: BidirectionalCollection {

    public func index(before i: Index) -> Index {
        let innerBaseStart = inner.base.startIndex
        precondition(i.start > innerBaseStart)

        let innerStart = inner.startIndex
        if i.start == inner.base.endIndex {
            assert(i.terminator == inner.endIndex)
            guard let previousInner = inner.index(i.terminator, offsetBy: -1, limitedBy: innerStart) else {
                // The whole collection is a terminator-less line.
                return Index(start: innerBaseStart, terminator: i.terminator)
            }

            if previousInner.indices.upperBound == i.terminator.indices.lowerBound {
                // If this branch is reached, then the expression in the
                // else-branch can't work.  (It'll be the same as endIndex.)  So
                // search for the prior line terminator.
                guard let twoBack = inner.index(previousInner, offsetBy: -1, limitedBy: innerStart) else {
                    return Index(start: innerBaseStart, terminator: previousInner)
                }

                return Index(start: twoBack.indices.upperBound, terminator: previousInner)
            } else {
                return Index(start: previousInner.indices.upperBound, terminator: i.terminator)
            }
        } else {
            let previousInner = inner.index(before: i.terminator)
            assert(previousInner.indices.upperBound == i.start)
            guard let twoBack = inner.index(previousInner, offsetBy: -1, limitedBy: innerStart) else {
                // The previousTerminator is the end of the first line.
                return Index(start: innerBaseStart, terminator: previousInner)
            }

            return Index(start: twoBack.indices.upperBound, terminator: previousInner)
        }
    }

}

// MARK: Adaptor Generators

extension Collection {

    /// Returns a collection of the locations of each line that can be parsed
    /// from this collection, using the given predicates to identify line-
    /// breaking element values.
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
    /// - Returns: A collection adaptor vending the locations (as index tuples)
    ///   of each line.
    public func lineLocations(considering targets: LineTerminatorSearchTargets, isCarriageReturn: @escaping (Element) -> Bool, isLineFeed: @escaping (Element) -> Bool) -> LineLocations<Self> {
        return LineLocations(inner: LineTerminatorLocations(base: self, targets: targets, isCr: isCarriageReturn, isLf: isLineFeed))
    }

}

extension Collection where Element: ExpressibleByUnicodeScalarLiteral & Equatable {

    /// Returns a collection of the locations of each line that can be parsed
    /// from this collection.
    ///
    /// - Parameter targets: The line-terminating subsequences to accept.
    ///
    /// - Returns: A collection adaptor vending the locations (as index tuples)
    ///   of each line.
    public func lineLocations(considering targets: LineTerminatorSearchTargets) -> LineLocations<Self> {
        return lineLocations(considering: targets, isCarriageReturn: { $0 == "\r" }, isLineFeed: { $0 == "\n" })
    }

}

extension Collection where Element: ExpressibleByIntegerLiteral & Equatable {

    /// Returns a collection of the locations of each line that can be parsed
    /// from this collection.
    ///
    /// - Parameter targets: The line-terminating subsequences to accept.
    ///
    /// - Returns: A collection adaptor vending the locations (as index tuples)
    ///   of each line.
    public func lineLocations(considering targets: LineTerminatorSearchTargets) -> LineLocations<Self> {
        return lineLocations(considering: targets, isCarriageReturn: { $0 == 0x0D }, isLineFeed: { $0 == 0x0A })
    }

}
