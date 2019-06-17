//
//  InternetLineBreakerValues.swift
//  InternetLines
//
//  Created by Daryle Walker on 6/15/19.
//

// MARK: - Line-Breaking Values

/// A type that supports values for the ASCII line feed and carriage return.
protocol InternetLineBreakerValues {

    /// The value of the ASCII+ carriage return control character's code point.
    static var crValue: Self { get }

    /// The value of the ASCII+ line feed control character's code point.
    static var lfValue: Self { get }

}

// MARK: Default Implementations

/// Default implementation for Unicode scalars.
extension InternetLineBreakerValues where Self: ExpressibleByUnicodeScalarLiteral {

    static var crValue: Self { return "\r" }
    static var lfValue: Self { return "\n" }

}

/// Default implementation for integers.
extension InternetLineBreakerValues where Self: ExpressibleByIntegerLiteral {

    static var crValue: Self { return 0x0D }
    static var lfValue: Self { return 0x0A }

}

// MARK: Default Instantiations

extension Unicode.Scalar: InternetLineBreakerValues {}

extension Int: InternetLineBreakerValues {}
extension UInt: InternetLineBreakerValues {}

extension Int8: InternetLineBreakerValues {}
extension UInt8: InternetLineBreakerValues {}
extension UInt16: InternetLineBreakerValues {}
extension UInt32: InternetLineBreakerValues {}
