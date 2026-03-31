// MARK: - Purpose: Renders transaction data into a formatted PDF document with summary and table
import Foundation
import SwiftUI
import UIKit // UIKit: PDF rendering not available in SwiftUI

// MARK: - PDF Renderer for Export

internal enum ExportPDFRenderer {

    /// Brand color for PDF headers — matches dark text palette.
    private static let brandColor = UIColor(Color(hex: "#3D3633"))

    private struct ExportSummary: Sendable {
        let totalIncome: Decimal
        let totalExpense: Decimal
        let balance: Decimal
    }

    internal static func render(
        transactions: [TransactionDTO],
        title: String
    ) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 595.0, height: 842.0)
        let margin: CGFloat = 40.0
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)
        let summary = computeSummary(transactions)
        let dateFormatter = makeDateFormatter()

        return renderer.pdfData { context in
            context.beginPage()
            var y = margin
            y = drawHeader(
                title, in: context, at: y,
                pageWidth: pageRect.width, margin: margin
            )
            y = drawSummary(
                summary, in: context, at: y, margin: margin
            )
            y = drawTableHeader(in: context, at: y, margin: margin)

            for dto in transactions {
                if y > pageRect.height - margin - 30 {
                    context.beginPage()
                    y = margin
                    y = drawTableHeader(
                        in: context, at: y, margin: margin
                    )
                }
                y = drawRow(
                    dto, dateFormatter: dateFormatter,
                    in: context, at: y, margin: margin
                )
            }
        }
    }

    // MARK: - Helpers

    private static func makeDateFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd/MM/yyyy"
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter
    }

    private static func computeSummary(
        _ transactions: [TransactionDTO]
    ) -> ExportSummary {
        let income = transactions
            .filter { $0.type == .income }
            .reduce(Decimal.zero) { $0 + $1.amount }
        let expense = transactions
            .filter { $0.type == .expense }
            .reduce(Decimal.zero) { $0 + $1.amount }
        return ExportSummary(
            totalIncome: income,
            totalExpense: expense,
            balance: income - expense
        )
    }

    private static func drawHeader(
        _ title: String,
        in context: UIGraphicsPDFRendererContext,
        at y: CGFloat,
        pageWidth: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var currentY = y
        currentY = drawBrandLine(at: currentY, pageWidth: pageWidth)
        currentY = drawSubtitleLine(title, at: currentY, pageWidth: pageWidth)
        return currentY
    }

    private static func drawBrandLine(
        at y: CGFloat, pageWidth: CGFloat
    ) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18),
            .foregroundColor: Self.brandColor,
        ]
        let brand = "Quản Lý Chi Tiêu" as NSString
        let size = brand.size(withAttributes: attrs)
        brand.draw(
            at: CGPoint(x: (pageWidth - size.width) / 2, y: y),
            withAttributes: attrs
        )
        return y + size.height + 8
    }

    private static func drawSubtitleLine(
        _ title: String, at y: CGFloat, pageWidth: CGFloat
    ) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 14),
            .foregroundColor: UIColor.darkGray,
        ]
        let titleNS = title as NSString
        let size = titleNS.size(withAttributes: attrs)
        titleNS.draw(
            at: CGPoint(x: (pageWidth - size.width) / 2, y: y),
            withAttributes: attrs
        )
        return y + size.height + 16
    }

    private static func drawSummary(
        _ summary: ExportSummary,
        in context: UIGraphicsPDFRendererContext,
        at y: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        var currentY = y
        let labelAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 11),
            .foregroundColor: UIColor.darkGray,
        ]
        let valueAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
        ]
        let lines: [(String, Decimal)] = [
            (String(localized: "Tổng thu nhập:"), summary.totalIncome),
            (String(localized: "Tổng chi tiêu:"), summary.totalExpense),
            (String(localized: "Số dư:"), summary.balance),
        ]
        for (index, (label, amount)) in lines.enumerated() {
            let text = "\(label) \(formatVND(amount))" as NSString
            let attrs = index == lines.count - 1
                ? valueAttrs : labelAttrs
            text.draw(
                at: CGPoint(x: margin, y: currentY),
                withAttributes: attrs
            )
            currentY += 18
        }
        currentY += 12
        return currentY
    }

    private static func drawTableHeader(
        in context: UIGraphicsPDFRendererContext,
        at y: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.white,
        ]
        let bgRect = CGRect(x: margin, y: y, width: 515, height: 20)
        context.cgContext.setFillColor(Self.brandColor.cgColor)
        context.cgContext.fill(bgRect)

        let columns = [
            String(localized: "Ngày"),
            String(localized: "Danh mục"),
            String(localized: "Loại"),
            String(localized: "Số tiền"),
            String(localized: "Ghi chú"),
        ]
        let xPos = columnPositions(margin: margin)
        for (index, col) in columns.enumerated() {
            (col as NSString).draw(
                at: CGPoint(x: xPos[index], y: y + 4),
                withAttributes: attrs
            )
        }
        return y + 24
    }

    private static func drawRow(
        _ dto: TransactionDTO,
        dateFormatter: DateFormatter,
        in context: UIGraphicsPDFRendererContext,
        at y: CGFloat,
        margin: CGFloat
    ) -> CGFloat {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.darkText,
        ]
        let xPos = columnPositions(margin: margin)

        let values = [
            dateFormatter.string(from: dto.date),
            dto.categoryName,
            dto.type.displayName,
            formatVND(dto.amount),
            String(dto.note.prefix(30)),
        ]
        for (index, value) in values.enumerated() {
            (value as NSString).draw(
                at: CGPoint(x: xPos[index], y: y + 2),
                withAttributes: attrs
            )
        }

        context.cgContext.setStrokeColor(UIColor.lightGray.cgColor)
        context.cgContext.setLineWidth(0.5)
        context.cgContext.move(to: CGPoint(x: margin, y: y + 18))
        context.cgContext.addLine(
            to: CGPoint(x: margin + 515, y: y + 18)
        )
        context.cgContext.strokePath()
        return y + 20
    }

    private static func columnPositions(
        margin: CGFloat
    ) -> [CGFloat] {
        [
            margin + 4, margin + 84, margin + 194,
            margin + 274, margin + 384,
        ]
    }

    private static func formatVND(_ amount: Decimal) -> String {
        let number = NSDecimalNumber(decimal: amount)
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "vi_VN")
        formatter.numberStyle = .currency
        formatter.currencyCode = "VND"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: number) ?? "\(amount)"
    }
}
