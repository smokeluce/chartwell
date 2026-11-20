import Cocoa

final class MainViewController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {

    private var all: [Encounter] = []
    private var visible: [Encounter] = []
    private var patientName = ""

    private let table = NSTableView()
    private let searchField = NSSearchField()
    private let statusLabel = NSTextField(labelWithString: "")
    private let emptyLabel = NSTextField(labelWithString: "Open a records JSON file to begin")
    private let pdfButton = NSButton(title: "Export PDF", target: nil, action: nil)
    private let wordButton = NSButton(title: "Export Word", target: nil, action: nil)

    private let nameOption = NameOptionView(frame: .zero)

    private let defaults = UserDefaults.standard
    private let lastFileKey = "lastRecordsPath"

    // MARK: - UI

    private func prep<T: NSView>(_ v: T) -> T {
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }

    override func loadView() {
        let root = NSView(frame: NSRect(x: 0, y: 0, width: 980, height: 640))
        root.wantsLayer = true
        root.layer?.backgroundColor = Theme.background.cgColor
        self.view = root

        // Header
        let header = prep(NSView())
        header.wantsLayer = true
        header.layer?.backgroundColor = Theme.navy.cgColor

        let title = prep(NSTextField(labelWithString: "Chartwell"))
        title.font = NSFont.systemFont(ofSize: 26, weight: .semibold)
        title.textColor = .white

        let subtitle = prep(NSTextField(labelWithString: "Turn encounter records into form-ready documents"))
        subtitle.font = NSFont.systemFont(ofSize: 12)
        subtitle.textColor = NSColor(white: 1, alpha: 0.65)

        let openButton = prep(NSButton(title: "Open Records\u{2026}", target: self, action: #selector(openRecords)))
        openButton.bezelStyle = .rounded

        header.addSubview(title)
        header.addSubview(subtitle)
        header.addSubview(openButton)

        // Toolbar row
        searchField.placeholderString = "Filter encounters"
        searchField.sendsSearchStringImmediately = true
        searchField.target = self
        searchField.action = #selector(filterChanged)
        _ = prep(searchField)

        statusLabel.font = NSFont.systemFont(ofSize: 12)
        statusLabel.textColor = Theme.secondaryText
        _ = prep(statusLabel)

        for b in [pdfButton, wordButton] {
            b.bezelStyle = .rounded
            b.isEnabled = false
            _ = prep(b)
        }

        // Table
        addColumn("date", "Date", 110, 90)
        addColumn("facility", "Facility", 200, 140)
        addColumn("address", "Address", 190, 120)
        addColumn("provider", "Provider", 150, 110)
        addColumn("reason", "Reason for visit", 220, 160)
        table.dataSource = self
        table.delegate = self
        table.rowHeight = 52
        table.usesAlternatingRowBackgroundColors = true
        table.gridStyleMask = []
        table.intercellSpacing = NSSize(width: 0, height: 1)
        table.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle

        let scroll = prep(NSScrollView())
        scroll.documentView = table
        scroll.hasVerticalScroller = true
        scroll.borderType = .noBorder

        emptyLabel.font = NSFont.systemFont(ofSize: 15)
        emptyLabel.textColor = Theme.secondaryText
        _ = prep(emptyLabel)

        _ = prep(nameOption)
        for v in [header, searchField, statusLabel, pdfButton, wordButton, nameOption, scroll, emptyLabel] as [NSView] {
            root.addSubview(v)
        }

        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: root.topAnchor),
            header.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            header.heightAnchor.constraint(equalToConstant: 76),

            title.leadingAnchor.constraint(equalTo: header.leadingAnchor, constant: 24),
            title.topAnchor.constraint(equalTo: header.topAnchor, constant: 12),
            subtitle.leadingAnchor.constraint(equalTo: title.leadingAnchor),
            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 0),
            openButton.trailingAnchor.constraint(equalTo: header.trailingAnchor, constant: -24),
            openButton.centerYAnchor.constraint(equalTo: header.centerYAnchor),

            searchField.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 14),
            searchField.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 24),
            searchField.widthAnchor.constraint(equalToConstant: 240),

            statusLabel.leadingAnchor.constraint(equalTo: searchField.trailingAnchor, constant: 16),
            statusLabel.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),

            wordButton.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -24),
            wordButton.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),
            pdfButton.trailingAnchor.constraint(equalTo: wordButton.leadingAnchor, constant: -8),
            pdfButton.centerYAnchor.constraint(equalTo: searchField.centerYAnchor),

            nameOption.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 12),
            nameOption.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 24),
            nameOption.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -24),
            nameOption.heightAnchor.constraint(equalToConstant: 26),

            scroll.topAnchor.constraint(equalTo: nameOption.bottomAnchor, constant: 12),
            scroll.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 24),
            scroll.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -24),
            scroll.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -24),

            emptyLabel.centerXAnchor.constraint(equalTo: scroll.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: scroll.centerYAnchor)
        ])
    }

    private func addColumn(_ id: String, _ title: String, _ width: CGFloat, _ minWidth: CGFloat) {
        let c = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: id))
        c.title = title
        c.width = width
        c.minWidth = minWidth
        table.addTableColumn(c)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        pdfButton.target = self
        pdfButton.action = #selector(exportPDF)
        updateStatus()
        if let path = defaults.string(forKey: lastFileKey),
            FileManager.default.fileExists(atPath: path) {
            load(URL(fileURLWithPath: path), quiet: true)
        }
    }

    // MARK: - Actions

    @objc private func openRecords() {
        let panel = NSOpenPanel()
        panel.allowedFileTypes = ["json"]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.message = "Choose your records JSON file"
        panel.begin { [weak self] response in
            if response == .OK, let url = panel.url {
                self?.load(url)
            }
        }
    }

    @objc private func filterChanged() {
        applyFilter()
    }

    @objc private func exportPDF() {
        let groups = Grouping.byFacility(visible)
        guard !groups.isEmpty else { return }
        let name = nameOption.effectiveName
        let stamp = DateFormatter()
        stamp.locale = Locale(identifier: "en_US_POSIX")
        stamp.dateFormat = "yyyy-MM-dd"
        let panel = NSSavePanel()
        panel.allowedFileTypes = ["pdf"]
        panel.nameFieldStringValue = "Future Medical Treatment Log - " + stamp.string(from: Date()) + ".pdf"
        panel.message = "Export the form as a PDF"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            if FormPDFRenderer().render(name: name, groups: groups, to: url) {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            } else {
                let alert = NSAlert()
                alert.messageText = "Could not create the PDF"
                alert.informativeText = "Check that the destination is writable and try again."
                alert.runModal()
            }
        }
    }

    @objc private func addressEdited(_ sender: NSTextField) {
        let row = table.row(for: sender)
        guard row >= 0, row < visible.count else { return }
        AddressBook.shared.setAddress(sender.stringValue, for: visible[row].facility)
        table.reloadData()
    }

    // MARK: - Data

    private func load(_ url: URL, quiet: Bool = false) {
        do {
            let file = try EncounterFile.load(from: url)
            all = file.encounters.sorted {
                ($0.dateValue ?? Date.distantPast, $0.visitID) < ($1.dateValue ?? Date.distantPast, $1.visitID)
            }
            patientName = file.patient ?? ""
            nameOption.setRecordsName(patientName)
            defaults.set(url.path, forKey: lastFileKey)
            applyFilter()
        } catch {
            if !quiet { NSAlert(error: error).runModal() }
        }
    }

    private func applyFilter() {
        let q = searchField.stringValue.trimmingCharacters(in: .whitespaces).lowercased()
        visible = q.isEmpty ? all : all.filter { $0.searchText.contains(q) }
        table.reloadData()
        emptyLabel.isHidden = !all.isEmpty
        updateStatus()
    }

    private func updateStatus() {
        pdfButton.isEnabled = !visible.isEmpty
        if all.isEmpty {
            statusLabel.stringValue = ""
        } else if visible.count == all.count {
            statusLabel.stringValue = "\(all.count) encounters" + (patientName.isEmpty ? "" : "  \u{2022}  \(patientName)")
        } else {
            statusLabel.stringValue = "\(visible.count) of \(all.count) encounters"
        }
    }

    // MARK: - Table

    func numberOfRows(in tableView: NSTableView) -> Int {
        return visible.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let column = tableColumn, row < visible.count else { return nil }
        let e = visible[row]
        let id = column.identifier

        let cell: NSTableCellView
        if let reused = tableView.makeView(withIdentifier: id, owner: self) as? NSTableCellView {
            cell = reused
        } else {
            cell = makeCell(id)
        }

        var text = ""
        var font = NSFont.systemFont(ofSize: 13)
        var color = Theme.primaryText
        switch id.rawValue {
        case "date":
            text = e.displayDate
            font = NSFont.systemFont(ofSize: 13, weight: .medium)
        case "facility":
            text = e.facility
        case "address":
            text = AddressBook.shared.resolved(for: e)
        case "provider":
            text = e.doctor
            color = Theme.secondaryText
        default:
            text = e.reason
        }
        cell.textField?.stringValue = text
        let isAddress = (id.rawValue == "address")
        cell.textField?.isEditable = isAddress
        cell.textField?.isSelectable = isAddress
        cell.textField?.placeholderString = isAddress ? "Click to add address" : nil
        cell.textField?.font = font
        cell.textField?.textColor = color
        cell.toolTip = text
        return cell
    }

    private func makeCell(_ id: NSUserInterfaceItemIdentifier) -> NSTableCellView {
        let cell = NSTableCellView()
        cell.identifier = id
        let tf = NSTextField(wrappingLabelWithString: "")
        tf.translatesAutoresizingMaskIntoConstraints = false
        tf.lineBreakMode = .byTruncatingTail
        tf.maximumNumberOfLines = 2
        tf.isSelectable = false
        tf.target = self
        tf.action = #selector(addressEdited(_:))
        cell.addSubview(tf)
        cell.textField = tf
        NSLayoutConstraint.activate([
            tf.leadingAnchor.constraint(equalTo: cell.leadingAnchor, constant: 10),
            tf.trailingAnchor.constraint(equalTo: cell.trailingAnchor, constant: -10),
            tf.centerYAnchor.constraint(equalTo: cell.centerYAnchor)
        ])
        return cell
    }
}
