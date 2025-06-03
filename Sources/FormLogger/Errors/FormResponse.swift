//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents possible responses from a form submission.
///
/// Conforms to the `Error` protocol to allow for error handling where appropriate.
public enum FormResponse: Error {

    /// The request was malformed or invalid.
    case badRequest

    /// Authentication failed or the user is not authorised.
    case unauthorized

    /// A server-side error occurred.
    case serverError

    /// An unspecified or unexpected error occurred.
    case unexpectedError

    /// The form was submitted successfully and returned a success message.
    case successMessage
}
