// After: production file contains only the view
// Smaller compile unit — incremental rebuilds are faster

import SwiftUI

struct ContentView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.headline)
    }
}
