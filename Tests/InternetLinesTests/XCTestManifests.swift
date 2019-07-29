import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(LineTerminatorLocationsTests.allTests),
        testCase(LineLocationsTests.allTests),
        testCase(LineSequenceTests.allTests),
    ]
}
#endif
