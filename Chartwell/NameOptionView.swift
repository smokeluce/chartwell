import Cocoa

final class NameOptionView: NSView, NSTextFieldDelegate {
    private let label = NSTextField(labelWithString: "Printed name:")
    private let field = NSTextField()
    private let check = NSButton(checkboxWithTitle: "Use name from records file", target: nil, action: nil)
    private(set) var recordsName = ""

    var effectiveName: String {
        return Settings.shared.useRecordsName ? recordsName : Settings.shared.customName
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        build()
    }

    required init?(coder decoder: NSCoder) {
        fatalError("init(coder:) not used")
    }

    private func build() {
        label.font = NSFont.systemFont(ofSize: 12)
        label.textColor = Theme.secondaryText
        field.font = NSFont.systemFont(ofSize: 13)
        field.delegate = self
        check.target = self
        check.action = #selector(toggled)
        check.font = NSFont.systemFont(ofSize: 12)
        for v in [label, field, check] as [NSView] {
            v.translatesAutoresizingMaskIntoConstraints = false
            addSubview(v)
        }
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            field.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
            field.centerYAnchor.constraint(equalTo: centerYAnchor),
            field.widthAnchor.constraint(equalToConstant: 280),
            check.leadingAnchor.constraint(equalTo: field.trailingAnchor, constant: 16),
            check.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        refresh()
    }

    func setRecordsName(_ name: String) {
        recordsName = name
        refresh()
    }

    @objc private func toggled() {
        let on = (check.state == .on)
        Settings.shared.useRecordsName = on
        if !on && Settings.shared.customName.isEmpty {
            Settings.shared.customName = recordsName
        }
        refresh()
    }

    func controlTextDidChange(_ obj: Notification) {
        if !Settings.shared.useRecordsName {
            Settings.shared.customName = field.stringValue
        }
    }

    private func refresh() {
        let useRecords = Settings.shared.useRecordsName
        check.state = useRecords ? .on : .off
        field.isEnabled = !useRecords
        field.stringValue = useRecords ? recordsName : Settings.shared.customName
    }
}
