// Core module: shared networking infrastructure.
// All feature modules depend on Core, but Core depends on nothing else.
// Changing this file rebuilds Core + every module that imports it.
// Changing FeatureHome or FeatureProfile does NOT rebuild this file.

import Foundation

public protocol NetworkClientProtocol {
    func fetch<T: Decodable & Sendable>(_ type: T.Type, from url: URL) async throws -> T
}

public final class NetworkClient: NetworkClientProtocol {
    public static let shared = NetworkClient()
    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func fetch<T: Decodable & Sendable>(_ type: T.Type, from url: URL) async throws -> T {
        let (data, _) = try await session.data(from: url)
        return try JSONDecoder().decode(T.self, from: data)
    }
}
