import Foundation

/// ⌘1–⌘5 open the list on screen. An empty root list widens that to ⌘1–⌘0.
enum ResultSlots {
    static let count = 5

    /// How many leading rows a chord may address. An empty root shows up to ten.
    static func limit(emptyRoot: Bool) -> Int {
        emptyRoot ? FavoriteSlots.digits.count : count
    }

    /// The selectable ordinal for this digit, or nil when the list's range does not include it.
    static func ordinal(forSlot slot: Int, emptyRoot: Bool) -> Int? {
        guard (0..<limit(emptyRoot: emptyRoot)).contains(slot) else { return nil }
        return slot
    }

    /// The row a result slot activates, skipping rows that cannot be opened.
    static func rowIndex(
        forSlot slot: Int, limit: Int = count, count rowCount: Int, isSelectable: (Int) -> Bool
    ) -> Int? {
        guard (0..<limit).contains(slot) else { return nil }
        var seen = 0
        for index in 0..<rowCount where isSelectable(index) {
            if seen == slot { return index }
            seen += 1
        }
        return nil
    }

    static func digit(at ordinal: Int, limit: Int = count) -> Character? {
        guard (0..<limit).contains(ordinal) else { return nil }
        return FavoriteSlots.digit(at: ordinal)
    }

    /// Digits for the first selectable rows, in the order the palette indexes them.
    static func digits<Row: Identifiable>(
        numbering: Bool, rows: [Row], selectable: (Row) -> Bool, limit: Int = count
    ) -> [Row.ID: Character] {
        guard numbering else { return [:] }
        var marks: [Row.ID: Character] = [:]
        var slot = 0
        for row in rows where selectable(row) {
            if slot < limit, let digit = FavoriteSlots.digit(at: slot) {
                marks[row.id] = digit
            }
            slot += 1
            if slot >= limit { break }
        }
        return marks
    }
}
