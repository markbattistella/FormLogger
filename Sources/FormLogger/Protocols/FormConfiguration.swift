//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
@_exported import SimpleLogger

/// A protocol defining the configuration requirements for a form submission system.
///
/// Implementations provide the necessary details for behaviour, data handling, and external
/// integration.
public protocol FormConfiguration {

    /// The endpoint URL where the form data should be submitted.
    var apiURL: URL { get }

    /// The maximum number of characters allowed in user input fields (e.g. title or description).
    var characterLimit: Int { get }

    /// A Boolean value indicating whether the form should automatically clear after submission.
    var shouldClearForm: Bool { get }

    /// The delay (in seconds) before the form is cleared after a successful submission.
    var clearFormDelay: TimeInterval { get }

    /// The logger configuration used to determine which logs to fetch or export with the form.
    var loggerManager: LoggerManager { get }

    /// The strategy used to determine which repository to submit the form to.
    var repository: RepositoryResolver { get }
}
