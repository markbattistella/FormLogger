//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
@_exported import SimpleLogger

/// A configuration protocol defining dependencies and behavioural options for a form submission
/// flow.
///
/// Types conforming to `FormConfiguration` must provide the necessary settings and dependencies
/// for the form to operate, including network targets, logging, and persistence behaviour.
public protocol FormConfiguration {

    /// The base URL for API requests related to the form.
    var apiURL: URL { get }

    /// The maximum number of characters allowed in text input fields.
    var characterLimit: Int { get }

    /// Indicates whether the form should be cleared after a successful submission.
    var shouldClearForm: Bool { get }

    /// The delay (in seconds) before the form is cleared, if `shouldClearForm` is `true`.
    var clearFormDelay: Duration { get }

    /// A logging manager used to record form events and errors.
    var loggerManager: LoggerManager { get }

    /// A resolver that provides access to data repositories used by the form.
    var repository: RepositoryResolver { get }

    var customMetadata: [String : String]? { get }
}

public extension FormConfiguration {
    var customMetadata: [String : String]? { nil }
}
