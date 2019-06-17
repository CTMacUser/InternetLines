import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(InternetLinesTests.allTests),
        testCase(InternetLineBreakerValuesTests.allTests),
    ]
}
#endif
