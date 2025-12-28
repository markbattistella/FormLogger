//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import SimpleLogger

/// Configuration requirements for form submission behaviour.
///
/// Conforming types define endpoints, limits, repository resolution, and logging behaviour used
/// by the form system.
public protocol FormConfiguration {

    /// The API endpoint used to submit form data.
    var apiURL: URL { get }

    /// The maximum number of characters allowed in the form message.
    ///
    /// Values exceeding this limit may be rejected or truncated.
    var characterLimit: Int { get }

    /// A Boolean value indicating whether the form should be cleared after a successful
    /// submission.
    var shouldClearForm: Bool { get }

    /// The delay applied before clearing the form after submission.
    ///
    /// This value is only relevant when `shouldClearForm` is `true`.
    var clearFormDelay: Duration { get }

    /// The repository resolution strategy used to determine the target GitHub repository for
    /// submissions.
    var repository: Repository.Resolver { get }

    /// Optional custom metadata to include with each form submission.
    var customMetadata: [String : String]? { get }

    /// A Boolean value indicating whether submissions should be treated as a dry run and not actually sent to the backend.
    var isDryRun: Bool { get }

    /// Allows the configuration to customise logging behaviour.
    ///
    /// - Parameter loggerManager: The logger manager used by the form system.
    func configureLogger(_ loggerManager: LoggerManager)
}

public extension FormConfiguration {

    /// The default maximum number of characters allowed in the form message.
    ///
    /// The default value is `500`.
    var characterLimit: Int { 500 }

    /// A Boolean value indicating whether the form is cleared after submission.
    ///
    /// The default value is `true`.
    var shouldClearForm: Bool { true }

    /// The default delay before clearing the form after submission.
    ///
    /// The default value is 10 seconds.
    var clearFormDelay: Duration { .seconds(10) }

    /// Default custom metadata included with form submissions.
    ///
    /// The default value is `nil`.
    var customMetadata: [String : String]? { nil }

    /// A Boolean value indicating whether submissions are treated as a dry run.
    ///
    /// The default value is `false`.
    var isDryRun: Bool { false }

    /// Configures logging for the form system.
    ///
    /// The default implementation performs no additional configuration.
    func configureLogger(_ loggerManager: LoggerManager) {}
}
