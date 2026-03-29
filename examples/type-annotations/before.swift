// Before: Unannotated inference sites that slow the Swift type checker.
// Each $0 shorthand and missing return type forces the compiler to infer types from context.

import Foundation

struct Item {
    let id: Int
    let name: String
    let isValid: Bool
    let score: Double
}

struct TransformedItem {
    let id: Int
    let displayName: String
}

func processItems(_ items: [Item]) -> [TransformedItem] {
    // Problem 1: Chained calls with $0 shorthand — compiler must infer type at each step
    let result = items
        .filter { $0.isValid }
        .filter { $0.score > 0.5 }
        .map { TransformedItem(id: $0.id, displayName: $0.name.uppercased()) }

    return result
}

// Problem 2: Empty collection literal without explicit type
let validIds = [Int]()
let scoreMap = [String: Double]()

// Problem 3: Closure without parameter type in a callback context
func fetchItems(completion: ([Item]) -> Void) { /* ... */ }

func loadData() {
    fetchItems { items in
        // items type is inferred — forces type checker to propagate context
        let sorted = items.sorted { $0.score > $1.score }
        _ = sorted
    }
}
