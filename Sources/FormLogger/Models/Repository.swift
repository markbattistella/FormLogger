//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A structure representing a code repository, including the owner's username and the repository
/// name.
///
/// Conforms to `Encodable` for use in API requests or data serialization.
public struct Repository: Encodable {

    /// The username or organisation that owns the repository.
    public let username: String

    /// The name of the repository.
    public let repository: String

    /// Creates a new `Repository` instance.
    ///
    /// - Parameters:
    ///   - username: The owner of the repository.
    ///   - repository: The name of the repository.
    public init(username: String, repository: String) {
        self.username = username
        self.repository = repository
    }
}
