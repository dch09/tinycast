import Foundation

@main
struct ResultSlotsTest {
    static func main() {
        var failures = 0

        func check(_ description: String, _ condition: @autoclosure () -> Bool) {
            if condition() {
                print("PASS  \(description)")
            } else {
                print("FAIL  \(description)")
                failures += 1
            }
        }

        check("five results, not the favorite ten", ResultSlots.count == 5)
        check("⌘1 opens the first result", ResultSlots.ordinal(forSlot: 0, emptyRoot: false) == 0)
        check("⌘5 opens the fifth result", ResultSlots.ordinal(forSlot: 4, emptyRoot: false) == 4)
        check("⌘6 is not a result slot", ResultSlots.ordinal(forSlot: 5, emptyRoot: false) == nil)
        check("⌘0 is not a result slot", ResultSlots.ordinal(forSlot: 9, emptyRoot: false) == nil)
        check("a negative slot is not a result", ResultSlots.ordinal(forSlot: -1, emptyRoot: false) == nil)
        check("an empty root keeps ⌘1", ResultSlots.ordinal(forSlot: 0, emptyRoot: true) == 0)
        check("an empty root keeps ⌘6", ResultSlots.ordinal(forSlot: 5, emptyRoot: true) == 5)
        check("an empty root keeps ⌘0", ResultSlots.ordinal(forSlot: 9, emptyRoot: true) == 9)
        check("an empty root stops after ⌘0", ResultSlots.ordinal(forSlot: 10, emptyRoot: true) == nil)
        check(
            "an empty field still has a first row",
            ResultSlots.rowIndex(forSlot: 0, limit: ResultSlots.limit(emptyRoot: true), count: 3) { _ in
                true
            } == 0)
        check(
            "an empty field with three rows ignores ⌘4",
            ResultSlots.rowIndex(forSlot: 3, limit: ResultSlots.limit(emptyRoot: true), count: 3) { _ in
                true
            } == nil)
        check(
            "an empty list has nothing to open",
            ResultSlots.rowIndex(forSlot: 0, limit: ResultSlots.limit(emptyRoot: true), count: 0) { _ in
                true
            } == nil)

        for slot in 0..<ResultSlots.count {
            check(
                "result slot \(slot) is the same key as that favorite",
                ResultSlots.ordinal(forSlot: slot, emptyRoot: false) == slot
                    && ResultSlots.ordinal(forSlot: slot, emptyRoot: true) == slot
                    && ResultSlots.digit(at: slot) == FavoriteSlots.digit(at: slot))
        }
        check("the sixth search result has no digit", ResultSlots.digit(at: 5) == nil)
        check(
            "the sixth empty-root row is ⌘6",
            ResultSlots.digit(at: 5, limit: ResultSlots.limit(emptyRoot: true)) == "6")
        check(
            "the tenth empty-root row is ⌘0",
            ResultSlots.digit(at: 9, limit: ResultSlots.limit(emptyRoot: true)) == "0")

        let selectable = [false, true, false, true, true, true, true, true, true]
        check(
            "⌘1 skips a leading header",
            ResultSlots.rowIndex(forSlot: 0, count: selectable.count, isSelectable: { selectable[$0] }) == 1)
        check(
            "⌘2 is the next selectable row",
            ResultSlots.rowIndex(forSlot: 1, count: selectable.count, isSelectable: { selectable[$0] }) == 3)
        check(
            "⌘5 stays inside the selectable rows",
            ResultSlots.rowIndex(forSlot: 4, count: selectable.count, isSelectable: { selectable[$0] }) == 6)
        check(
            "⌘6 is not assigned once five rows are taken",
            ResultSlots.rowIndex(forSlot: 5, count: selectable.count, isSelectable: { selectable[$0] }) == nil)
        check(
            "a short list has no fifth slot",
            ResultSlots.rowIndex(forSlot: 4, count: 2, isSelectable: { _ in true }) == nil)
        check(
            "an empty root reaches the seventh selectable row",
            ResultSlots.rowIndex(
                forSlot: 6, limit: ResultSlots.limit(emptyRoot: true), count: selectable.count,
                isSelectable: { selectable[$0] }
            ) == 8)
        check(
            "an empty root stops when the rows run out",
            ResultSlots.rowIndex(
                forSlot: 7, limit: ResultSlots.limit(emptyRoot: true), count: selectable.count,
                isSelectable: { selectable[$0] }
            ) == nil)

        struct Mark: Identifiable {
            let id: String
            let selectable: Bool
        }
        let rows = [
            Mark(id: "header", selectable: false),
            Mark(id: "card", selectable: true),
            Mark(id: "section", selectable: false),
            Mark(id: "first", selectable: true),
            Mark(id: "second", selectable: true),
            Mark(id: "third", selectable: true),
            Mark(id: "fourth", selectable: true),
            Mark(id: "fifth", selectable: true),
            Mark(id: "sixth", selectable: true),
        ]
        let marks = ResultSlots.digits(numbering: true, rows: rows, selectable: \.selectable)
        check("a header takes no digit", marks["header"] == nil)
        check("the card is ⌘1", marks["card"] == "1")
        check("the next result is ⌘2", marks["first"] == "2")
        check("the fifth result is ⌘5", marks["fourth"] == "5")
        check("the sixth result has no chord", marks["fifth"] == nil)
        let wide = ResultSlots.digits(
            numbering: true, rows: rows, selectable: \.selectable,
            limit: ResultSlots.limit(emptyRoot: true))
        check("an empty root numbers the sixth row", wide["fifth"] == "6")
        check("an empty root numbers the seventh row", wide["sixth"] == "7")
        check(
            "numbering off marks nothing",
            ResultSlots.digits(numbering: false, rows: rows, selectable: \.selectable).isEmpty)

        if failures > 0 {
            print("\(failures) failed")
            exit(1)
        }
    }
}
