// FeatureHome module: imports Core, knows nothing about FeatureProfile.
// Lives in Sources/FeatureHome/ — isolated from other feature modules.
// Changing this file rebuilds only FeatureHome + the App target.
// FeatureProfile and Core are NOT recompiled.

import Core

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public private(set) var user: User?
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?

    private let userService: UserServiceProtocol

    public init(userService: UserServiceProtocol) {
        self.userService = userService
    }

    public func loadUser(id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            user = try await userService.fetchUser(id: id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
