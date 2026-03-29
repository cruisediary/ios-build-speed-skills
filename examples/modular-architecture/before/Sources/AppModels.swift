// Before: All models, services, and view models in one monolithic target.
// Any change to User, Post, or their services triggers recompilation of
// everything in this file — and every file that imports this target.

import Foundation

// MARK: - Models (mixed with services in the same target)

struct User: Codable {
    let id: String
    var name: String
    var email: String
}

struct Post: Codable {
    let id: String
    let authorId: String
    var title: String
    var body: String
}

// MARK: - Networking (same target as models and views)

final class NetworkClient {
    static let shared = NetworkClient()
    private let session: URLSession

    private init(session: URLSession = .shared) {
        self.session = session
    }

    func fetch<T: Decodable>(_ type: T.Type, from url: URL) async throws -> T {
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}

final class UserService {
    private let client: NetworkClient

    init(client: NetworkClient = .shared) {
        self.client = client
    }

    func fetchUser(id: String) async throws -> User {
        let url = URL(string: "https://api.example.com/users/\(id)")!
        return try await client.fetch(User.self, from: url)
    }
}

final class PostService {
    private let client: NetworkClient

    init(client: NetworkClient = .shared) {
        self.client = client
    }

    func fetchPosts(for userId: String) async throws -> [Post] {
        let url = URL(string: "https://api.example.com/users/\(userId)/posts")!
        return try await client.fetch([Post].self, from: url)
    }
}

// MARK: - View Models (same target — changes here recompile models and services)

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var user: User?
    @Published var posts: [Post] = []
    @Published var isLoading = false

    private let userService = UserService()
    private let postService = PostService()

    func load(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            user = try await userService.fetchUser(id: userId)
            posts = try await postService.fetchPosts(for: userId)
        } catch {
            print("Load failed: \(error)")
        }
    }
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false

    private let userService = UserService()

    func load(userId: String) async {
        isLoading = true
        defer { isLoading = false }
        user = try? await userService.fetchUser(id: userId)
    }
}
