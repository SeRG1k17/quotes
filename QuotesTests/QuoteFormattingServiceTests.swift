import XCTest
@testable import Quotes

final class QuoteFormattingServiceTests: XCTestCase {
    private let sut = QuoteFormattingService()

    func testPrice_groupsFractionalPartByThreeDigits() {
        let result = sut.price(decimal("0.043356"), minStep: decimal("0.000001"))
        XCTAssertEqual(result, "0.043 356")
    }

    func testAbsoluteChange_usesPositivePrefix() {
        let result = sut.absoluteChange(decimal("1.37035"), minStep: decimal("0.001"))
        XCTAssertEqual(result, "+1.370")
    }

    func testPercentChange_formatsWithTwoFractionDigitsAndPercentSign() {
        XCTAssertEqual(sut.percentChange(decimal("3.18")), "+3.18%")
        XCTAssertEqual(sut.percentChange(decimal("-0.86")), "-0.86%")
    }
}

private func decimal(_ string: String) -> Decimal {
    guard let value = Decimal(string: string) else {
        fatalError("Failed to parse Decimal: \(string)")
    }
    return value
}
