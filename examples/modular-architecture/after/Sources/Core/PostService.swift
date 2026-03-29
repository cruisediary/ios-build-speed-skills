// Core module: shared Post domain type and service.
// FeatureHome imports this to display posts in a feed.

import Foundation

public struct Post: Codable, Sendable {
    public let id: String
    public let authorId: String
    public var title: String
    public var body: String

    public init(id: String, authorId: String, title: String, body: String) {
        self.id = id
        self.authorId = authorId
        self.title = title
        self.body = body
    }
}

public protocol PostServiceProtocol {
    func fetchPosts(for userId: String) async throws -> [Post]
}

public final class PostService: PostServiceProtocol {
    private let client: NetworkClientProtocol

    public init(client: NetworkClientProtocol = NetworkClient.shared) {
        self.client = client
    }

    public func fetchPosts(for userId: String) async throws -> [Post] {
        let url = URL(string: "https://api.example.com/users/\(userId)/posts")!
        return try await client.fetch([Post].self, from: url)
    }
}
