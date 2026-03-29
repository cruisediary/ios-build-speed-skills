// Core module: shared infrastructure used by all feature modules.
// Lives in Sources/Core/ — imported by FeatureHome, FeatureProfile, etc.
// Changing this file rebuilds Core + all modules that depend on it.
// Changing FeatureHome does NOT rebuild this file.

import Foundation

public protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
}

public struct User: Codable, Sendable {
    public let id: String
    public var name: String
    public var email: String

    public init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}

public final class UserService: UserServiceProtocol {
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetchUser(id: String) async throws -> User {
        let url = URL(string: "https://api.example.com/users/\(id)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(User.self, from: data)
    }
}
