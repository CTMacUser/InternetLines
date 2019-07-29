# InternetLines

Parse CRLF-terminated lines from raw data or other character code points.

## Installation

The library is designed to be used with the [Swift Package Manager](https://swift.org/package-manager/).  Add this library's Git URL as a dependency to your SPM project.  Otherwise, manually add the files in the "Sources/InternetLines/" sub-directory to your project.

## Usage

The main support type is `LineTerminatorSearchTargets`, which specifies which line-breaking sequences should be searched for.  It's an `OptionSet`, so multiple sequences can be searched for at once.  The current search targets are:

- CRLF, carriage-return followed by line-feed: The terminator used for text lines passed along for various Internet protocols.  It's also used for text files for the Windows operating system family.
- LF, line-feed only: The terminator used for text files for Unix (and related) operating systems.
- CR, carriage-return only: A terminator used for text files only for some ancient operating systems, like pre-NeXT macOS.
- CRCRLF, two carriage-returns and a line-feed: It's not an official terminator, but can appear by mistake when writing text files on Windows systems.

The main functionality is expressed through types that wrap a `Sequence` or `Collection` with the right `Element` type.  The element type can be either `UnicodeScalar` or one of the default integer types.  A wrapper object can be obtained through helper methods added as `Sequence` or `Collection` extensions:

- `Sequence.parsedLines(considering:)` returns a `LineSequence`, which parses then vends each line from the source sequence as a `(data: [Element], terminator: [Element])`, where the main part of the line is separated from the terminator upon return.  At most one part of a returned tuple is empty.
- `Collection.lineLocations(considering:)` returns a `LineLocations`, which is an (optionally bi-directional) collection that vends `(start: Base.Index, border: Base.Index, end: Base.Index)`, which is a tuple that returns the start and end of each parsed line in the source along with the border between the main part of the line and its terminator.
- `Collection.lineTerminatorLocations(considering:)` returns a `LineTerminatorLocations`, which is an (optionally bi-directional) collection that vends a `Range<Base.Index>` for each line-breaking sequence within the source, specifying the terminator's location.
