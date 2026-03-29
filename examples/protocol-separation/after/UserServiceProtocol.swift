// After (1/2): Protocol + domain type in their own file.
// Only files that need to reference the protocol or User type import this.
// Changing UserService.swift no longer forces recompilation of protocol-only consumers.

import Foundation

// User lives here — it is part of the protocol's public interface contract
struct User: Codable {
    let id: String
    var name: String
    var email: String
}

protocol UserServiceProtocol {
    func fetchUser(id: String) async throws -> User
    func updateUser(_ user: User) async throws
}
