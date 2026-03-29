// FeatureProfile module: imports Core, knows nothing about FeatureHome.
// Changing this file rebuilds only FeatureProfile + the App target.
// Core, FeatureHome, and their tests are NOT recompiled.

import Core

@MainActor
public final class ProfileViewModel: ObservableObject {
    @Published public private(set) var user: User?
    @Published public private(set) var posts: [Post] = []
    @Published public private(set) var isLoading: Bool = false
    @Published public private(set) var errorMessage: String?

    private let userService: UserServiceProtocol
    private let postService: PostServiceProtocol

    public init(
        userService: UserServiceProtocol,
        postService: PostServiceProtocol
    ) {
        self.userService = userService
        self.postService = postService
    }

    public func load(userId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            async let fetchedUser = userService.fetchUser(id: userId)
            async let fetchedPosts = postService.fetchPosts(for: userId)
            (user, posts) = try await (fetchedUser, fetchedPosts)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
