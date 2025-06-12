//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents the various error responses that can occur when submitting a form.
public enum FormResponse: Error {

    /// The request was malformed or contained invalid parameters.
    case badRequest

    /// The user is not authorised to perform the action.
    case unauthorized

    /// The server encountered an internal error.
    case serverError

    /// An unknown or unexpected error occurred.
    case unexpectedError

    /// One or more form fields failed validation.
    /// - Parameter invalidFields: A set of fields that didn't meet validation criteria.
    case validationFailed(invalidFields: Set<FormField>)

    /// A network-related error occurred, typically due to connectivity issues.
    ///
    /// - Parameter URLError: The underlying URL error returned by the system.
    case networkError(URLError)
}

extension FormResponse: LocalizedError {

    /// A user-friendly title representing the error type.
    public var errorTitle: String {
        switch self {
            case .badRequest:
                return "Invalid Request"
            case .unauthorized:
                return "Access Denied"
            case .serverError:
                return "Server Error"
            case .unexpectedError:
                return "Unexpected Error"
            case .validationFailed:
                return "Invalid Fields"
            case .networkError:
                return "Network Error"
        }
    }

    /// A detailed, localised description of the error for display to the user.
    public var errorDescription: String? {
        switch self {
            case .badRequest:
                return "The request was invalid. Please check the form and try again."

            case .unauthorized:
                return "You’re not authorised to perform this action. Please log in and try again."

            case .serverError:
                return "Something went wrong on our end. Please try again later."

            case .unexpectedError:
                return "An unexpected error occurred. Please try again or contact support."

            case .validationFailed(let invalidFields):
                
                // Formats the invalid fields as a bulleted list.
                let fieldList = invalidFields
                    .map { "• \($0.label)" }
                    .sorted()
                    .joined(separator: "\n")

                return "Some fields need to be corrected:\n\n\(fieldList)"

            case .networkError(let error):
                // Uses a custom extension or mapping to convert error code into a user-friendly
                // message.
                let baseMessage = error.code.friendlyDescription
                return "\(baseMessage)\n\nIf this keeps happening, please contact us on social media or via email."
        }
    }
}
