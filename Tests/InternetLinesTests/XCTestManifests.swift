import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(InternetLinesTests.allTests),
        testCase(LineTerminatorLocationsTests.allTests),
        testCase(LineLocationsTests.allTests),
        testCase(LineSequenceTests.allTests),
    ]
}
#endif
