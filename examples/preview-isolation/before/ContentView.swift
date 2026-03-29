// Before: preview code mixed into production file
// PreviewProvider compiles in Release and expands the ContentView.swift compile unit

import SwiftUI

struct ContentView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
    }
}

// Preview code below — not guarded by #if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(title: "Hello, World!")
    }
}
