import XCTest

import InternetLinesTests

var tests = [XCTestCaseEntry]()
tests += LineTerminatorLocationsTests.allTests()
tests += LineLocationsTests.allTests()
tests += LineSequenceTests.allTests()
XCTMain(tests)
