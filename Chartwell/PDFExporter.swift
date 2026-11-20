import Cocoa

final class FormPDFRenderer {
    private let pageW: CGFloat = 612
    private let pageH: CGFloat = 792
    private let margin: CGFloat = 54
    private var contentW: CGFloat { return pageW - margin * 2 }
    private var bottom: CGFloat { return pageH - margin - 16 }

    private var ctx: CGContext?
    private var dry = true
    private var y: CGFloat = 0
    private var page = 0
    private var total = 0
    private var name = ""

    private let dateW: CGFloat = 92
    private let providerW: CGFloat = 150
    private let pad: CGFloat = 6

    private let ink = NSColor(srgbRed: 0.10, green: 0.12, blue: 0.16, alpha: 1)
    private let muted = NSColor(srgbRed: 0.40, green: 0.44, blue: 0.50, alpha: 1)
    private let rule = NSColor(srgbRed: 0.80, green: 0.83, blue: 0.87, alpha: 1)
    private let tint = NSColor(srgbRed: 0.93, green: 0.95, blue: 0.97, alpha: 1)

    // MARK: - Entry point

    func render(name: String, groups: [FacilityGroup], to url: URL) -> Bool {
        self.name = name
        dry = true
        layout(groups)
        total = page

        var box = CGRect(x: 0, y: 0, width: pageW, height: pageH)
        let info = [kCGPDFContextTitle as String: "Future Medical Treatment Log",
                    kCGPDFContextAuthor as String: name] as CFDictionary
        guard let c = CGContext(url as CFURL, mediaBox: &box, info) else { return false }
        ctx = c
        dry = false
        layout(groups)
        c.closePDF()
        ctx = nil
        return true
    }

    private func layout(_ groups: [FacilityGroup]) {
        page = 0
        beginPage()
        drawTitle(groups)
        for g in groups { drawGroup(g) }
        endPage()
    }

    // MARK: - Pages

    private func beginPage() {
        page += 1
        y = margin
        guard !dry, let c = ctx else { return }
        c.beginPDFPage(nil)
        c.saveGState()
        c.translateBy(x: 0, y: pageH)
        c.scaleBy(x: 1, y: -1)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: c, flipped: true)
    }

    private func endPage() {
        guard !dry, let c = ctx else { return }
        drawFooter()
        NSGraphicsContext.restoreGraphicsState()
        c.restoreGState()
        c.endPDFPage()
    }

    private func breakPage() {
        endPage()
        beginPage()
    }

    // MARK: - Drawing helpers

    private func attr(_ s: String, size: CGFloat, weight: NSFont.Weight = .regular,
                      color: NSColor, align: NSTextAlignment = .left) -> NSAttributedString {
        let p = NSMutableParagraphStyle()
        p.alignment = align
        p.lineBreakMode = .byWordWrapping
        p.lineSpacing = 1.5
        return NSAttributedString(string: s, attributes: [
            .font: NSFont.systemFont(ofSize: size, weight: weight),
            .foregroundColor: color,
            .paragraphStyle: p
        ])
    }

    private func height(_ s: NSAttributedString, width: CGFloat) -> CGFloat {
        let r = s.boundingRect(with: NSSize(width: width, height: 10000),
                               options: [.usesLineFragmentOrigin, .usesFontLeading])
        return ceil(r.height)
    }

    private func draw(_ s: NSAttributedString, x: CGFloat, y ty: CGFloat, width: CGFloat) {
        if dry { return }
        s.draw(with: NSRect(x: x, y: ty, width: width, height: 10000),
               options: [.usesLineFragmentOrigin, .usesFontLeading])
    }

    @discardableResult
    private func place(_ s: NSAttributedString, x: CGFloat, width: CGFloat) -> CGFloat {
        let h = height(s, width: width)
        draw(s, x: x, y: y, width: width)
        y += h
        return h
    }

    private func fill(_ r: CGRect, _ color: NSColor) {
        guard !dry, let c = ctx else { return }
        c.setFillColor(color.cgColor)
        c.fill(r)
    }

    private func hline(y ly: CGFloat, from x0: CGFloat, to x1: CGFloat, color: NSColor, width w: CGFloat = 0.5) {
        guard !dry, let c = ctx else { return }
        c.setStrokeColor(color.cgColor)
        c.setLineWidth(w)
        c.move(to: CGPoint(x: x0, y: ly))
        c.addLine(to: CGPoint(x: x1, y: ly))
        c.strokePath()
    }

    // MARK: - Title block

    private func drawTitle(_ groups: [FacilityGroup]) {
        place(attr("FUTURE MEDICAL TREATMENT LOG", size: 20, weight: .bold, color: Theme.navy),
              x: margin, width: contentW)
        y += 6
        fill(CGRect(x: margin, y: y, width: contentW, height: 2), Theme.accent)
        y += 16

        let value = attr(name.isEmpty ? "______________________________" : name,
                         size: 14, weight: .semibold, color: ink)
        draw(attr("Name:", size: 12, color: muted), x: margin, y: y + 1.5, width: 50)
        let h = height(value, width: contentW - 56)
        draw(value, x: margin + 50, y: y, width: contentW - 56)
        y += max(h, 16) + 4

        let all = groups.flatMap { $0.encounters }
        let dates = all.compactMap { $0.dateValue }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US")
        df.dateFormat = "MMM d, yyyy"
        var summary = "\(all.count) \(all.count == 1 ? "encounter" : "encounters") at \(groups.count) \(groups.count == 1 ? "facility" : "facilities")"
        if let first = dates.min(), let last = dates.max() {
            summary += "  \u{2022}  " + df.string(from: first) + " to " + df.string(from: last)
        }
        place(attr(summary, size: 10, color: muted), x: margin, width: contentW)
        y += 22
    }

    // MARK: - Facility blocks

    private func facilityTitle(_ g: FacilityGroup, continued: Bool) -> NSAttributedString {
        return attr(continued ? g.facility + " (continued)" : g.facility,
                    size: 12.5, weight: .semibold, color: Theme.navy)
    }

    private func addressHeight(_ g: FacilityGroup) -> CGFloat {
        if g.address.isEmpty { return 18 }
        return max(height(attr(g.address, size: 10.5, color: ink), width: contentW - 52), 14) + 4
    }

    private func headingHeight(_ g: FacilityGroup, continued: Bool) -> CGFloat {
        var h = height(facilityTitle(g, continued: continued), width: contentW) + 4
        if !continued { h += addressHeight(g) }
        return h + 20
    }

    private func drawHeading(_ g: FacilityGroup, continued: Bool) {
        place(facilityTitle(g, continued: continued), x: margin, width: contentW)
        y += 4
        if !continued {
            draw(attr("Address:", size: 10, color: muted), x: margin, y: y + 1, width: 50)
            if g.address.isEmpty {
                hline(y: y + 13, from: margin + 52, to: margin + contentW, color: muted)
            } else {
                draw(attr(g.address, size: 10.5, color: ink), x: margin + 52, y: y, width: contentW - 52)
            }
            y += addressHeight(g)
        }
        fill(CGRect(x: margin, y: y, width: contentW, height: 20), tint)
        let reasonW = contentW - dateW - providerW
        let cols: [(String, CGFloat, CGFloat)] = [
            ("DATE VISITED", margin, dateW),
            ("PROVIDER", margin + dateW, providerW),
            ("BRIEF REASON FOR VISIT", margin + dateW + providerW, reasonW)
        ]
        for (title, x, w) in cols {
            draw(attr(title, size: 8, weight: .semibold, color: muted), x: x + pad, y: y + 6, width: w - pad * 2)
        }
        y += 20
    }

    private func dateAttr(_ e: Encounter) -> NSAttributedString {
        return attr(e.displayDate, size: 10, weight: .medium, color: ink)
    }

    private func providerAttr(_ e: Encounter) -> NSAttributedString {
        return attr(e.doctor.isEmpty ? "\u{2014}" : e.doctor, size: 10, color: ink)
    }

    private func reasonAttr(_ e: Encounter) -> NSAttributedString {
        return attr(e.reason, size: 10, color: ink)
    }

    private func rowHeight(_ e: Encounter) -> CGFloat {
        let reasonW = contentW - dateW - providerW
        let a = height(dateAttr(e), width: dateW - pad * 2)
        let b = height(providerAttr(e), width: providerW - pad * 2)
        let c = height(reasonAttr(e), width: reasonW - pad * 2)
        return max(a, max(b, c)) + pad * 2
    }

    private func drawRow(_ e: Encounter, height h: CGFloat) {
        let reasonW = contentW - dateW - providerW
        draw(dateAttr(e), x: margin + pad, y: y + pad, width: dateW - pad * 2)
        draw(providerAttr(e), x: margin + dateW + pad, y: y + pad, width: providerW - pad * 2)
        draw(reasonAttr(e), x: margin + dateW + providerW + pad, y: y + pad, width: reasonW - pad * 2)
        hline(y: y + h, from: margin, to: margin + contentW, color: rule)
        y += h
    }

    private func drawGroup(_ g: FacilityGroup) {
        guard !g.encounters.isEmpty else { return }
        let need = headingHeight(g, continued: false) + rowHeight(g.encounters[0])
        if y + need > bottom { breakPage() }
        drawHeading(g, continued: false)
        for e in g.encounters {
            let h = rowHeight(e)
            if y + h > bottom {
                breakPage()
                drawHeading(g, continued: true)
            }
            drawRow(e, height: h)
        }
        y += 20
    }

    // MARK: - Footer

    private func drawFooter() {
        let fy = pageH - margin + 6
        hline(y: fy - 6, from: margin, to: margin + contentW, color: rule)
        let leftText = name.isEmpty ? "Future Medical Treatment Log" : name + "  \u{2022}  Future Medical Treatment Log"
        draw(attr(leftText, size: 8.5, color: muted), x: margin, y: fy, width: contentW - 100)
        draw(attr("Page \(page) of \(total)", size: 8.5, color: muted, align: .right),
             x: margin + contentW - 100, y: fy, width: 100)
    }
}
