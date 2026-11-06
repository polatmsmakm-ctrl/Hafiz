import SwiftUI

/// Wrapping layout that fills each row from right to left (Arabic reading order).
struct FlowLayout: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 10

    private func buildRows(maxWidth: CGFloat, subviews: Subviews) -> [[(Int, CGSize)]] {
        var result: [[(Int, CGSize)]] = [[]]
        var x: CGFloat = 0
        for (i, s) in subviews.enumerated() {
            let size = s.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                result.append([])
                x = 0
            }
            result[result.count - 1].append((i, size))
            x += size.width + spacing
        }
        return result
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxW = proposal.width ?? 320
        let rows = buildRows(maxWidth: maxW, subviews: subviews)
        var h: CGFloat = 0
        for (ri, r) in rows.enumerated() {
            h += r.map { $0.1.height }.max() ?? 0
            if ri < rows.count - 1 { h += lineSpacing }
        }
        return CGSize(width: maxW, height: h)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = buildRows(maxWidth: bounds.width, subviews: subviews)
        var y = bounds.minY
        for r in rows {
            let rowH = r.map { $0.1.height }.max() ?? 0
            var x = bounds.maxX
            for (i, size) in r {
                subviews[i].place(
                    at: CGPoint(x: x - size.width, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x -= size.width + spacing
            }
            y += rowH + lineSpacing
        }
    }
}
