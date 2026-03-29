// After (2/2): Implementation only — no protocol or domain type definitions.
// Changing this file only recompiles consumers that depend on UserService directly.
//
// Note: UserServiceProtocol and User are defined in UserServiceProtocol.swift.
// Both files belong to the same Xcode target/module and compile together.

import Foundation

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
