import XCTest

import InternetLinesTests

var tests = [XCTestCaseEntry]()
tests += InternetLinesTests.allTests()
tests += LineTerminatorLocationsTests.allTests()
XCTMain(tests)
