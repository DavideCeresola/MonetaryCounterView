import XCTest
import MonetaryCounterView

class MonetaryCounterBaseTests: XCTestCase {
    
    private(set) lazy var counterView: MonetaryCounterView = {
        let view = MonetaryCounterView()
        view.configure(with: "EUR")
        return view
    }()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        counterView.number = .zero
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func expectedResult(_ number: NSDecimalNumber) {
        
        guard let stackView = counterView.subviews.first as? UIStackView else {
            return XCTFail("Expected StackView")
        }
        
        let labels = stackView.arrangedSubviews.compactMap { $0 as? UILabel }
        
        guard
            !labels.isEmpty
        else {
            return XCTFail("Expected UILabels as subviews")
        }
        
        _ = XCTWaiter.wait(for: [expectation(description: "Wait for n seconds")], timeout: 1.0)
        
        let expectedNumberString = counterView.numberFormatter.string(from: number)
        let currentNumberString = labels.compactMap { $0.text }.joined()
        
        let failureMessage = "Not Equals:\nExpected -> \(expectedNumberString!)\nCurrent -> \(currentNumberString)"
        
        XCTAssert(expectedNumberString == currentNumberString, failureMessage)
        
    }
    
}
