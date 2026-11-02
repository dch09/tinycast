import AppKit

/// A cup in the menu bar while a hold is active. Hidden the rest of the time.
@MainActor
final class CaffeineMenuBar: NSObject {
    var onDecaffeinate: () -> Void = {}
    private var item: NSStatusItem?

    func update(title: String, summary: String) {
        let item = self.item ?? NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if self.item == nil {
            item.autosaveName = "Caffeinate"
            self.item = item
        }
        guard let button = item.button else { return }
        if button.image == nil {
            let image = NSImage(
                systemSymbolName: "cup.and.saucer.fill",
                accessibilityDescription: String(localized: "Caffeinate"))
            image?.isTemplate = true
            button.image = image
        }
        button.imagePosition = title.isEmpty ? .imageOnly : .imageLeading
        button.title = title
        button.toolTip = summary
        if item.menu == nil {
            item.menu = menu(summary: summary)
        } else {
            item.menu?.items.first?.title = summary
        }
    }

    func hide() {
        guard let item else { return }
        NSStatusBar.system.removeStatusItem(item)
        self.item = nil
    }

    private func menu(summary: String) -> NSMenu {
        let menu = NSMenu()
        let status = NSMenuItem(title: summary, action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        let stop = NSMenuItem(
            title: String(localized: "Decaffeinate"), action: #selector(stop), keyEquivalent: "")
        stop.target = self
        menu.addItem(stop)
        return menu
    }

    @objc private func stop() { onDecaffeinate() }
}
