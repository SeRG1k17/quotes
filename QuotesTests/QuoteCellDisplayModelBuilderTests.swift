import XCTest
@testable import Quotes

final class QuoteCellDisplayModelBuilderTests: XCTestCase {
    private var sut: QuoteCellDisplayModelBuilder!

    override func setUp() {
        super.setUp()
        sut = QuoteCellDisplayModelBuilder(quoteFormattingService: QuoteFormattingService())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testMakeDisplayModel_containsFormattedStringsAndDirection() {
        let quote = Quote(
            symbol: "SBER",
            companyName: "Sberbank",
            market: "MCX",
            lastPrice: decimal("233.749"),
            absoluteChange: decimal("7.217"),
            percentChange: decimal("3.18"),
            minStep: decimal("0.001")
        )

        let model = sut.makeDisplayModel(quote: quote, previousQuote: nil)

        XCTAssertEqual(model.symbol, "SBER")
        XCTAssertEqual(model.subtitle, "MCX | Sberbank")
        XCTAssertEqual(model.percentText, "+3.18%")
        XCTAssertEqual(model.valueText, "233.749 (+7.217)")
        XCTAssertEqual(model.direction, .up)
        XCTAssertNil(model.flashDirection)
    }

    func testMakeDisplayModel_setsFlashDirectionWhenPercentChanges() {
        let previousQuote = Quote(
            symbol: "VTBR",
            companyName: "VTB ao",
            market: "MCX",
            lastPrice: decimal("0.043356"),
            absoluteChange: decimal("0.000040"),
            percentChange: decimal("0.09"),
            minStep: decimal("0.000001")
        )
        let quote = Quote(
            symbol: "VTBR",
            companyName: "VTB ao",
            market: "MCX",
            lastPrice: decimal("0.043356"),
            absoluteChange: decimal("0.000040"),
            percentChange: decimal("0.10"),
            minStep: decimal("0.000001")
        )

        let model = sut.makeDisplayModel(quote: quote, previousQuote: previousQuote)

        XCTAssertEqual(model.flashDirection, .up)
    }
}

private func decimal(_ string: String) -> Decimal {
    guard let value = Decimal(string: string) else {
        fatalError("Failed to parse Decimal: \(string)")
    }
    return value
}
