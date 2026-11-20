import Foundation

final class FormDocxRenderer {
    private let navy = "1B2844"
    private let accent = "2E75B5"
    private let muted = "667080"
    private let ink = "1A1F29"
    private let tint = "EDF2F7"
    private let ruleC = "CCD4DE"
    private let colW = [1840, 3000, 5240]

    private let head = "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n"
    private let nsW = "http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    private let nsR = "http://schemas.openxmlformats.org/officeDocument/2006/relationships"

    // MARK: - Entry point

    func render(name: String, groups: [FacilityGroup], to url: URL) -> Bool {
        let zip = ZipWriter()
        zip.add("[Content_Types].xml", contentTypes())
        zip.add("_rels/.rels", rootRels())
        zip.add("word/_rels/document.xml.rels", docRels())
        zip.add("word/document.xml", documentXML(name: name, groups: groups))
        zip.add("word/styles.xml", stylesXML())
        zip.add("word/footer1.xml", footerXML(name: name))
        do {
            try zip.finish().write(to: url, options: .atomic)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Package parts

    private func contentTypes() -> String {
        var s = head
        s += "<Types xmlns=\"http://schemas.openxmlformats.org/package/2006/content-types\">"
        s += "<Default Extension=\"rels\" ContentType=\"application/vnd.openxmlformats-package.relationships+xml\"/>"
        s += "<Default Extension=\"xml\" ContentType=\"application/xml\"/>"
        s += "<Override PartName=\"/word/document.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml\"/>"
        s += "<Override PartName=\"/word/styles.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml\"/>"
        s += "<Override PartName=\"/word/footer1.xml\" ContentType=\"application/vnd.openxmlformats-officedocument.wordprocessingml.footer+xml\"/>"
        s += "</Types>"
        return s
    }

    private func rootRels() -> String {
        var s = head
        s += "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
        s += "<Relationship Id=\"rId1\" Type=\"\(nsR)/officeDocument\" Target=\"word/document.xml\"/>"
        s += "</Relationships>"
        return s
    }

    private func docRels() -> String {
        var s = head
        s += "<Relationships xmlns=\"http://schemas.openxmlformats.org/package/2006/relationships\">"
        s += "<Relationship Id=\"rId1\" Type=\"\(nsR)/styles\" Target=\"styles.xml\"/>"
        s += "<Relationship Id=\"rId2\" Type=\"\(nsR)/footer\" Target=\"footer1.xml\"/>"
        s += "</Relationships>"
        return s
    }

    private func stylesXML() -> String {
        var s = head
        s += "<w:styles xmlns:w=\"\(nsW)\"><w:docDefaults><w:rPrDefault><w:rPr>"
        s += "<w:rFonts w:ascii=\"Calibri\" w:hAnsi=\"Calibri\" w:eastAsia=\"Calibri\" w:cs=\"Calibri\"/>"
        s += "<w:sz w:val=\"20\"/><w:szCs w:val=\"20\"/><w:lang w:val=\"en-US\"/>"
        s += "</w:rPr></w:rPrDefault><w:pPrDefault><w:pPr><w:spacing w:after=\"0\" w:line=\"252\" w:lineRule=\"auto\"/></w:pPr></w:pPrDefault></w:docDefaults>"
        s += "<w:style w:type=\"paragraph\" w:default=\"1\" w:styleId=\"Normal\"><w:name w:val=\"Normal\"/><w:qFormat/></w:style>"
        s += "</w:styles>"
        return s
    }

    // MARK: - XML helpers

    private func esc(_ t: String) -> String {
        var r = t.replacingOccurrences(of: "&", with: "&amp;")
        r = r.replacingOccurrences(of: "<", with: "&lt;")
        r = r.replacingOccurrences(of: ">", with: "&gt;")
        r = r.replacingOccurrences(of: "\"", with: "&quot;")
        return r
    }

    private func run(_ t: String, size: Int, bold: Bool = false, color: String) -> String {
        var s = "<w:r><w:rPr>"
        if bold { s += "<w:b/>" }
        s += "<w:color w:val=\"\(color)\"/><w:sz w:val=\"\(size)\"/><w:szCs w:val=\"\(size)\"/></w:rPr>"
        s += "<w:t xml:space=\"preserve\">\(esc(t))</w:t></w:r>"
        return s
    }

    private func para(_ runs: String, keepNext: Bool = false, before: Int = 0, after: Int = 0,
                      borderBottom: String? = nil) -> String {
        var pr = ""
        if keepNext { pr += "<w:keepNext/>" }
        if let c = borderBottom {
            pr += "<w:pBdr><w:bottom w:val=\"single\" w:sz=\"12\" w:space=\"4\" w:color=\"\(c)\"/></w:pBdr>"
        }
        pr += "<w:spacing w:before=\"\(before)\" w:after=\"\(after)\"/>"
        return "<w:p><w:pPr>\(pr)</w:pPr>\(runs)</w:p>"
    }

    private func fld(_ instr: String) -> String {
        let rp = "<w:rPr><w:color w:val=\"\(muted)\"/><w:sz w:val=\"17\"/><w:szCs w:val=\"17\"/></w:rPr>"
        var s = "<w:r>\(rp)<w:fldChar w:fldCharType=\"begin\"/></w:r>"
        s += "<w:r>\(rp)<w:instrText xml:space=\"preserve\"> \(instr) </w:instrText></w:r>"
        s += "<w:r>\(rp)<w:fldChar w:fldCharType=\"separate\"/></w:r>"
        s += "<w:r>\(rp)<w:t>1</w:t></w:r>"
        s += "<w:r>\(rp)<w:fldChar w:fldCharType=\"end\"/></w:r>"
        return s
    }

    private func cell(_ w: Int, _ text: String, size: Int, bold: Bool, color: String,
                      fill: String?, border: Bool, keepNext: Bool) -> String {
        var tc = "<w:tc><w:tcPr><w:tcW w:w=\"\(w)\" w:type=\"dxa\"/>"
        if border {
            tc += "<w:tcBorders><w:bottom w:val=\"single\" w:sz=\"4\" w:space=\"0\" w:color=\"\(ruleC)\"/></w:tcBorders>"
        }
        if let f = fill {
            tc += "<w:shd w:val=\"clear\" w:color=\"auto\" w:fill=\"\(f)\"/>"
        }
        tc += "</w:tcPr><w:p><w:pPr>"
        if keepNext { tc += "<w:keepNext/>" }
        tc += "</w:pPr>"
        if !text.isEmpty { tc += run(text, size: size, bold: bold, color: color) }
        tc += "</w:p></w:tc>"
        return tc
    }

    private func row(_ cells: [String], header: Bool) -> String {
        var s = "<w:tr><w:trPr><w:cantSplit/>"
        if header { s += "<w:tblHeader/>" }
        s += "</w:trPr>"
        s += cells.joined()
        s += "</w:tr>"
        return s
    }

    // MARK: - Document

    private func summary(_ groups: [FacilityGroup]) -> String {
        let all = groups.flatMap { $0.encounters }
        let dates = all.compactMap { $0.dateValue }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US")
        df.dateFormat = "MMM d, yyyy"
        var s = "\(all.count) \(all.count == 1 ? "encounter" : "encounters") at \(groups.count) \(groups.count == 1 ? "facility" : "facilities")"
        if let first = dates.min(), let last = dates.max() {
            s += "  \u{2022}  " + df.string(from: first) + " to " + df.string(from: last)
        }
        return s
    }

    private func groupXML(_ g: FacilityGroup) -> String {
        var x = para(run(g.facility, size: 25, bold: true, color: navy), keepNext: true, before: 120, after: 40)

        var addr = run("Address:  ", size: 20, color: muted)
        if g.address.isEmpty {
            addr += run("________________________________________", size: 20, color: muted)
        } else {
            addr += run(g.address, size: 21, color: ink)
        }
        x += para(addr, keepNext: true, after: 100)

        x += "<w:tbl><w:tblPr><w:tblW w:w=\"10080\" w:type=\"dxa\"/><w:tblLayout w:type=\"fixed\"/>"
        x += "<w:tblCellMar><w:top w:w=\"80\" w:type=\"dxa\"/><w:left w:w=\"100\" w:type=\"dxa\"/>"
        x += "<w:bottom w:w=\"80\" w:type=\"dxa\"/><w:right w:w=\"100\" w:type=\"dxa\"/></w:tblCellMar></w:tblPr>"
        x += "<w:tblGrid>" + colW.map { "<w:gridCol w:w=\"\($0)\"/>" }.joined() + "</w:tblGrid>"

        let titles = ["DATE VISITED", "PROVIDER", "BRIEF REASON FOR VISIT"]
        var headCells = [String]()
        for (i, t) in titles.enumerated() {
            headCells.append(cell(colW[i], t, size: 16, bold: true, color: muted, fill: tint, border: false, keepNext: true))
        }
        x += row(headCells, header: true)

        for (i, e) in g.encounters.enumerated() {
            let keep = (i == 0)
            let doctor = e.doctor.isEmpty ? "\u{2014}" : e.doctor
            var cells = [String]()
            cells.append(cell(colW[0], e.displayDate, size: 20, bold: false, color: ink, fill: nil, border: true, keepNext: keep))
            cells.append(cell(colW[1], doctor, size: 20, bold: false, color: ink, fill: nil, border: true, keepNext: keep))
            cells.append(cell(colW[2], e.reason, size: 20, bold: false, color: ink, fill: nil, border: true, keepNext: keep))
            x += row(cells, header: false)
        }
        x += "</w:tbl>"
        x += "<w:p><w:pPr><w:spacing w:before=\"0\" w:after=\"200\"/><w:rPr><w:sz w:val=\"8\"/></w:rPr></w:pPr></w:p>"
        return x
    }

    private func documentXML(name: String, groups: [FacilityGroup]) -> String {
        var b = para(run("FUTURE MEDICAL TREATMENT LOG", size: 40, bold: true, color: navy),
                     after: 160, borderBottom: accent)
        var nameRuns = run("Name:  ", size: 24, color: muted)
        nameRuns += run(name.isEmpty ? "______________________________" : name, size: 28, bold: true, color: ink)
        b += para(nameRuns, before: 200, after: 80)
        b += para(run(summary(groups), size: 20, color: muted), after: 320)
        for g in groups { b += groupXML(g) }

        var s = head
        s += "<w:document xmlns:w=\"\(nsW)\" xmlns:r=\"\(nsR)\"><w:body>"
        s += b
        s += "<w:sectPr><w:footerReference w:type=\"default\" r:id=\"rId2\"/>"
        s += "<w:pgSz w:w=\"12240\" w:h=\"15840\"/>"
        s += "<w:pgMar w:top=\"1080\" w:right=\"1080\" w:bottom=\"1080\" w:left=\"1080\" w:header=\"720\" w:footer=\"540\" w:gutter=\"0\"/>"
        s += "</w:sectPr></w:body></w:document>"
        return s
    }

    private func footerXML(name: String) -> String {
        let left = name.isEmpty ? "Future Medical Treatment Log" : name + "  \u{2022}  Future Medical Treatment Log"
        var p = "<w:p><w:pPr><w:pBdr><w:top w:val=\"single\" w:sz=\"4\" w:space=\"6\" w:color=\"\(ruleC)\"/></w:pBdr>"
        p += "<w:tabs><w:tab w:val=\"right\" w:pos=\"10080\"/></w:tabs></w:pPr>"
        p += run(left, size: 17, color: muted)
        p += "<w:r><w:tab/></w:r>"
        p += run("Page ", size: 17, color: muted)
        p += fld("PAGE")
        p += run(" of ", size: 17, color: muted)
        p += fld("NUMPAGES")
        p += "</w:p>"
        var s = head
        s += "<w:ftr xmlns:w=\"\(nsW)\">" + p + "</w:ftr>"
        return s
    }
}
