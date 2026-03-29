// After: Explicit type annotations reduce type-checker work.
// The compiler no longer needs to infer types from context at each call site.

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
    // Explicit parameter and return types: type checker resolves each step independently
    let result: [TransformedItem] = items
        .filter { (item: Item) -> Bool in item.isValid }
        .filter { (item: Item) -> Bool in item.score > 0.5 }
        .map { (item: Item) -> TransformedItem in
            TransformedItem(id: item.id, displayName: item.name.uppercased())
        }

    return result
}

// Explicit types on empty collection literals
let validIds: [Int] = []
let scoreMap: [String: Double] = [:]

// Explicit parameter type in closure
func fetchItems(completion: ([Item]) -> Void) { /* ... */ }

func loadData() {
    fetchItems { (items: [Item]) in
        let sorted: [Item] = items.sorted { (a: Item, b: Item) -> Bool in a.score > b.score }
        _ = sorted
    }
}
