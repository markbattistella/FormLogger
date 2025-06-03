//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A strategy for resolving which repository to use for a given form type.
///
/// This allows for flexibility in configuring either a single repository, distinct repositories
/// for each form type, or a shared repository with specific overrides.
public enum RepositoryResolver {

    /// A single repository used for all form types.
    case single(Repository)

    /// A mapping of form types to specific repositories.
    case multiple([FormType: Repository])

    /// A shared repository used by default, with specific overrides for certain form types.
    case partial(shared: Repository, overrides: [FormType: Repository])

    /// Returns the appropriate repository for the given form type.
    ///
    /// - Parameter formType: The form type for which a repository is requested.
    /// - Returns: The resolved `Repository` instance.
    ///
    /// - Note: If `.multiple` is used and the requested form type is not configured,
    ///   this will trigger a runtime failure.
    public func getRepository(for formType: FormType) -> Repository {
        switch self {
            case .single(let repository):
                return repository
            case .multiple(let repositories):
                guard let repository = repositories[formType] else {
                    preconditionFailure("No repository configured for form type: \(formType)")
                }
                return repository
            case .partial(let shared, let overrides):
                return overrides[formType] ?? shared
        }
    }
}
