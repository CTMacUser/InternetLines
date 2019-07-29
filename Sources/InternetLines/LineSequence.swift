//
//  LineSequence.swift
//  InternetLines
//
//  Created by Daryle Walker on 7/26/19.
//


// MARK: Line-Parsing Iterator

/// An iterator over the elements from a given iterator, parsed into llnes.
///
/// Which line-breaking sequences are used is determined by a given set of
/// targets.  All are common combinations of carriage-returns and line-feeds.
/// The testing of element values against a CR or LF is performed by the given
/// closures.
///
/// The vended elements are the parsed lines, returned as a tuple where the
/// first property is the line without its terminator, and the second property
/// is the terminator.  At most one is empty.
public struct LineIterator<SubSequence: RangeReplaceableCollection, Base: IteratorProtocol> where SubSequence.Element == Base.Element {

    /// The source of elements.
    var base: Base
    /// Which line-breaking sequences to search for.
    let targets: LineTerminatorSearchTargets
    /// The closure to identify carriage returns.
    let isCr: (Base.Element) -> Bool
    /// The closure to identify line feeds.
    let isLf: (Base.Element) -> Bool

    /// Cache of the pending elements.
    var cache: SubSequence

    /// Creates an iterator from the given source, target sequence list, and closures.
    init(_ base: Base, considering targets: LineTerminatorSearchTargets, isCarriageReturn: @escaping (Base.Element) -> Bool, isLineFeed: @escaping (Base.Element) -> Bool) {
        self.base = base
        self.targets = targets
        isCr = isCarriageReturn
        isLf = isLineFeed

        cache = SubSequence()
    }

}

extension LineIterator: IteratorProtocol {

    /// Load more elements into the cache, up to and past potential line-breaks.
    ///
    /// If the base iterator is already exhausted, then nothing is added to the
    /// cache.  Otherwise, the cache will gain a possibly-empty sequence of
    /// non-line-breaking elements, then a run of line-breaking elements, and a
    /// single non-line-breaking element to end the block.  The only way the
    /// block ends with either a line-breaking element or a non-line-breaking
    /// element that doesn't succeed a line-breaking one is if the iterator gets
    /// exhausted before the typical point.
    ///
    /// - Returns: The number of elements cached in this run.
    mutating private func load() -> Int {
        var isFirstPhase = true
        var count = 0
        loop: while let e = base.next() {
            cache.append(e)
            count += 1
            switch (isFirstPhase, isCr(e) || isLf(e)) {
            case (true, true):
                isFirstPhase.toggle()
            case (true, false):
                break
            case (false, true):
                break
            case (false, false):
                break loop
            }
        }
        return count
    }

    mutating public func next() -> (data: SubSequence, terminator: SubSequence)? {
        var oldCache = SubSequence()
        while true {
            // Check for whole lines, possibly empty, still in the cache.
            if let firstTerminator = cache.lineTerminatorLocations(considering: targets, isCarriageReturn: isCr, isLineFeed: isLf).first {
                defer { cache.removeSubrange(..<firstTerminator.upperBound) }
                return (data: oldCache + cache[..<firstTerminator.lowerBound], terminator: SubSequence(cache[firstTerminator]))
            }

            // Load in a new potential line.
            oldCache += cache
            cache.removeAll(keepingCapacity: true)
            guard load() > 0 else {
                // If this was reached, then every line was extracted and the
                // remainder drained from the base iterator.  So return that
                // remant.
                if oldCache.isEmpty {
                    return nil
                } else {
                    return (data: oldCache, terminator: SubSequence())
                }
            }
        }
    }

}

// MARK: Line-Parsing Sequence

/// A sequence over the elements from a given sequence, parsed into llnes.
///
/// Which line-breaking subsequences are used is determined by a given set of
/// targets.  All are common combinations of carriage-returns and line-feeds.
/// The testing of element values against a CR or LF is performed by the given
/// closures.
///
/// The vended elements are the parsed lines, returned as a tuple where the
/// first property is the line without its terminator, and the second property
/// is the terminator.  At most one is empty.
public struct LineSequence<SubSequence: RangeReplaceableCollection, Base: Sequence> where SubSequence.Element == Base.Element {

    /// The sequence to parse.
    let base: Base
    /// Which line-breaking sequences to search for.
    let targets: LineTerminatorSearchTargets
    /// The closure to identify carriage returns.
    let isCr: (Base.Element) -> Bool
    /// The closure to identify line feeds.
    let isLf: (Base.Element) -> Bool

}

extension LineSequence: Sequence {

    public __consuming func makeIterator() -> LineIterator<SubSequence, Base.Iterator> {
        return LineIterator(base.makeIterator(), considering: targets, isCarriageReturn: isCr, isLineFeed: isLf)
    }

    public var underestimatedCount: Int {
        return base.underestimatedCount.signum()
    }

}

// MARK: Adaptor Generators

extension Sequence {

    /// Returns a sequence of the lines parsed from this sequence, using the
    /// given targets for line breaks, the given predicates to identify line-
    /// breaking elements values, as tuples of segments of the given type.
    ///
    /// - Precondition: No element value can satisfy both `isCarriageReturn` and
    ///   `isLineFeed` simultaneously.
    ///
    /// - Parameter lineType: The type of the data and terminator parts of the
    ///   vended lines.
    /// - Parameter targets: The line-terminating subsequences to accept.
    /// - Parameter isCarriageReturn: A predicate that identifies a given
    ///   element value as a carriage return.
    /// - Parameter isLineFeed: A predicate that identifies a given element
    ///   value as a line feed.
    ///
    /// - Returns: A sequence adaptor vending the parsed lines (as tuples).
    public func parsedLines<T: RangeReplaceableCollection>(as lineType: T.Type, considering targets: LineTerminatorSearchTargets, isCarriageReturn: @escaping (Element) -> Bool, isLineFeed: @escaping (Element) -> Bool) -> LineSequence<T, Self> where T.Element == Element {
        return LineSequence(base: self, targets: targets, isCr: isCarriageReturn, isLf: isLineFeed)
    }

}

extension Sequence where Element: ExpressibleByUnicodeScalarLiteral & Equatable {

    /// Returns a sequence of the lines parsed from this sequence, using the
    /// given targets for line breaks, as tuples of segments of the given type.
    ///
    /// - Parameter lineType: The type of the data and terminator parts of the
    ///   vended lines.
    /// - Parameter targets: The line-terminating subsequences to accept.
    ///
    /// - Returns: A sequence adaptor vending the parsed lines (as tuples).
    public func parsedLines<T: RangeReplaceableCollection>(as lineType: T.Type, considering targets: LineTerminatorSearchTargets) -> LineSequence<T, Self> where T.Element == Element {
        return parsedLines(as: T.self, considering: targets, isCarriageReturn: { $0 == "\r" }, isLineFeed: { $0 == "\n" })
    }

    /// Returns a sequence of the lines parsed from this sequence, using the
    /// given targets for line breaks, as tuples of arrays.
    ///
    /// - Parameter targets: The line-terminating subsequences to accept.
    ///
    /// - Returns: A sequence adaptor vending the parsed lines (as tuples).
    public func parsedLines(considering targets: LineTerminatorSearchTargets) -> LineSequence<[Element], Self> {
        return parsedLines(as: Array.self, considering: targets)
    }

}

extension Sequence where Element: ExpressibleByIntegerLiteral & Equatable {

    /// Returns a sequence of the lines parsed from this sequence, using the
    /// given targets for line breaks, as tuples of segments of the given type.
    ///
    /// - Parameter lineType: The type of the data and terminator parts of the
    ///   vended lines.
    /// - Parameter targets: The line-terminating subsequences to accept.
    ///
    /// - Returns: A sequence adaptor vending the parsed lines (as tuples).
    public func parsedLines<T: RangeReplaceableCollection>(as lineType: T.Type, considering targets: LineTerminatorSearchTargets) -> LineSequence<T, Self> where T.Element == Element {
        return parsedLines(as: T.self, considering: targets, isCarriageReturn: { $0 == 0x0D }, isLineFeed: { $0 == 0x0A })
    }

    /// Returns a sequence of the lines parsed from this sequence, using the
    /// given targets for line breaks, as tuples of arrays.
    ///
    /// - Parameter targets: The line-terminating subsequences to accept.
    ///
    /// - Returns: A sequence adaptor vending the parsed lines (as tuples).
    public func parsedLines(considering targets: LineTerminatorSearchTargets) -> LineSequence<[Element], Self> {
        return parsedLines(as: Array.self, considering: targets)
    }

}
