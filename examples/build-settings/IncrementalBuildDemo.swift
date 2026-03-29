// This file demonstrates why SWIFT_COMPILATION_MODE = incremental matters.
//
// With incremental compilation (recommended for Debug):
//   Changing fetchUser() only recompiles UserRepository.swift.
//   The compiler emits one object file per source file and tracks dependencies.
//
// With whole-module compilation (the problematic default in some projects):
//   Changing fetchUser() recompiles every Swift file in the target,
//   because the compiler processes all files together in one pass.
//
// Related build settings (see examples/build-settings/after.xcconfig):
//   SWIFT_COMPILATION_MODE = incremental
//   SWIFT_OPTIMIZATION_LEVEL = -Onone
//   DEBUG_INFORMATION_FORMAT = dwarf

import Foundation

// MARK: - Domain

struct User: Codable {
    let id: String
    var name: String
    var email: String
}

// MARK: - Repository

/// Changing only this type triggers recompilation of this file only (incremental mode).
/// In whole-module mode the entire target is rebuilt regardless of which file changed.
final class UserRepository {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchUser(id: String) async throws -> User {
        let url = URL(string: "https://api.example.com/users/\(id)")!
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(User.self, from: data)
    }
}

// MARK: - View Model

/// Independently compiled in incremental mode.
/// A change here does not recompile UserRepository above.
@MainActor
final class UserViewModel: ObservableObject {
    @Published private(set) var user: User?
    private let repository: UserRepository

    init(repository: UserRepository = UserRepository()) {
        self.repository = repository
    }

    func load(id: String) async {
        user = try? await repository.fetchUser(id: id)
    }
}
