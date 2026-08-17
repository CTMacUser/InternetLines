# InternetLines[^old]

Split an ASCII sequence at its line-breaking octets.

## Usage

```swift
import InternetLines

let input = "Line 1\r\nLine 2\nLine 3\rLine 4"
let lines = Array(
  AnySequence(input.utf8)
    .internetLines
    .map { String(decoding: $0.line, as: UTF8.self) }
)
// ["Line 1", "Line 2", "Line 3", "Line 4"]
```

## Installation

Add the following to your `Package.swift` dependencies:

```swift
.package(url: "https://github.com/CTMacUser/InternetLines.git", from: "0.1.0")
```

[^old]: This is my second project with this name.
Here's a [link to the first](https://github.com/CTMacUser/InternetLines-old).
