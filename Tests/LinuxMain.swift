import XCTest

import InternetLinesTests

var tests = [XCTestCaseEntry]()
tests += InternetLinesTests.allTests()
tests += InternetLineBreakerValuesTests.allTests()
XCTMain(tests)
