//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A namespace for repository-related types.
public enum Repository {}

extension Repository {

    /// A GitHub repository descriptor.
    ///
    /// This type identifies a GitHub repository using an owner username and repository name.
    /// It is intended to be encoded and transmitted as part of a form submission or configuration
    /// payload.
    public struct Github: Encodable {

        /// The GitHub username or organisation that owns the repository.
        public let username: String

        /// The name of the GitHub repository.
        public let repository: String

        /// Creates a new GitHub repository descriptor.
        ///
        /// - Parameters:
        ///   - username: The GitHub username or organisation.
        ///   - repository: The name of the repository.
        public init(username: String, repository: String) {
            self.username = username
            self.repository = repository
        }
    }
}

extension Repository {

    /// A strategy for resolving a GitHub repository based on form type.
    ///
    /// This enum supports different repository configuration models, ranging from a single shared
    /// repository to per-form mappings and partial overrides.
    public enum Resolver {

        /// Uses a single repository for all form types.
        case single(Github)

        /// Uses a distinct repository for each form type.
        ///
        /// A repository must be provided for every supported form kind.
        case multiple([FormManager.Kind: Github])

        /// Uses a shared default repository with optional per-form overrides.
        case partial(shared: Github, overrides: [FormManager.Kind: Github])

        /// Resolves the GitHub repository for a given form kind.
        ///
        /// - Parameter kind: The form type requiring a repository.
        /// - Returns: The resolved `Github` repository.
        ///
        /// If no repository is configured for the given form kind in the `.multiple` case, this
        /// method triggers a precondition failure.
        public func getRepository(for kind: FormManager.Kind) -> Github {
            switch self {
                case .single(let repository):
                    return repository

                case .multiple(let repositories):
                    guard let repository = repositories[kind] else {
                        preconditionFailure("No repository configured for form type: \(kind)")
                    }
                    return repository

                case .partial(let shared, let overrides):
                    return overrides[kind] ?? shared
            }
        }
    }
}
