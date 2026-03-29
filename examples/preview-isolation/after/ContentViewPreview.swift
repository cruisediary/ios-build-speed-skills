// After: preview code in a dedicated file, guarded by #if DEBUG
// Excluded from Release builds — zero overhead in production

#if DEBUG
import SwiftUI

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(title: "Hello, World!")
    }
}
#endif
