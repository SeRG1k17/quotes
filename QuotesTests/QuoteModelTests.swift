import XCTest
@testable import Quotes

final class QuoteModelTests: XCTestCase {
    func testDirection_returnsUpWhenPercentIsPositive() {
        let quote = Quote(
            symbol: "SBER",
            companyName: "Sberbank",
            market: "MCX",
            lastPrice: decimal("233.749"),
            absoluteChange: decimal("0"),
            percentChange: decimal("3.18"),
            minStep: decimal("0.001")
        )

        XCTAssertEqual(quote.direction, .up)
    }

    func testDirection_returnsDownWhenAbsoluteChangeIsNegative() {
        let quote = Quote(
            symbol: "GAZP",
            companyName: "Gazprom ao",
            market: "MCX",
            lastPrice: decimal("201.73"),
            absoluteChange: decimal("-1.73"),
            percentChange: decimal("0"),
            minStep: decimal("0.01")
        )

        XCTAssertEqual(quote.direction, .down)
    }

    func testMerging_updatesOnlyProvidedFields() {
        let original = Quote(
            symbol: "RSTI",
            companyName: "Rosseti ao",
            market: "MCX",
            lastPrice: decimal("1.513"),
            absoluteChange: decimal("0.0597"),
            percentChange: decimal("4.11"),
            minStep: decimal("0.0001")
        )

        let update = PartialQuote(
            symbol: nil,
            companyName: "Rosseti PJSC",
            market: nil,
            lastPrice: decimal("1.6000"),
            absoluteChange: nil,
            percentChange: decimal("5.00"),
            minStep: nil
        )

        let merged = original.merging(with: update)

        XCTAssertEqual(merged.symbol, "RSTI")
        XCTAssertEqual(merged.companyName, "Rosseti PJSC")
        XCTAssertEqual(merged.market, "MCX")
        XCTAssertEqual(merged.lastPrice, decimal("1.6000"))
        XCTAssertEqual(merged.absoluteChange, decimal("0.0597"))
        XCTAssertEqual(merged.percentChange, decimal("5.00"))
        XCTAssertEqual(merged.minStep, decimal("0.0001"))
    }
}

private func decimal(_ string: String) -> Decimal {
    guard let value = Decimal(string: string) else {
        fatalError("Failed to parse Decimal: \(string)")
    }
    return value
}
