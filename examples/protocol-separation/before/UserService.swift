// Before: Protocol and implementation in the same file.
// Any change to fetchUser() forces recompilation of ALL files that import this module.

import Foundation

// Protocol defined alongside its implementation
protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
    func updateUser(_ user: User) async throws
}

struct User: Codable {
    let id: String
    var name: String
    var email: String
}

// Concrete implementation in the same file
final class UserService: UserServiceProtocol {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchUser(id: String) async throws -> User {
        let url = URL(string: "https://api.example.com/users/\(id)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(User.self, from: data)
    }

    func updateUser(_ user: User) async throws {
        var request = URLRequest(url: URL(string: "https://api.example.com/users/\(user.id)")!)
        request.httpMethod = "PUT"
        request.httpBody = try JSONEncoder().encode(user)
        _ = try await session.data(for: request)
    }
}
