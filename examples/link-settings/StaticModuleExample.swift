// Static module usage example.
//
// When MACH_O_TYPE = staticlib is set on FeatureHome and Core,
// the import syntax and API surface are identical to dynamic frameworks.
// The only difference is at link and launch time — no embedding, no dyld.
//
// App target (main app):
import FeatureHome   // statically linked — resolved at link time, not launch time
import Core          // statically linked

// FeatureHome (Sources/FeatureHome/SceneDelegate.swift):
import Core          // statically linked

// Public API works exactly the same way:
func makeHomeScene(userService: UserServiceProtocol) -> HomeViewModel {
    HomeViewModel(userService: userService)
}

// Build time comparison (example project, 15 internal modules):
//   Dynamic frameworks: link ~12s, launch overhead ~800ms
//   Static libraries:   link  ~4s, launch overhead   ~0ms (no dyld)
