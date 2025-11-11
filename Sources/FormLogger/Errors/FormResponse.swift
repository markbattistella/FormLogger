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
                return String(
                    localized: "Invalid Request",
                    comment: "Error title shown when the app cannot process the user's request due to invalid input or parameters."
                )
            case .unauthorized:
                return String(
                    localized: "Access Denied",
                    comment: "Error title shown when the user is not authorised to perform the requested action or access the resource."
                )
            case .serverError:
                return String(
                    localized: "Server Error",
                    comment: "Error title shown when the server returns an unexpected or invalid response."
                )
            case .unexpectedError:
                return String(
                    localized: "Unexpected Error",
                    comment: "Error title shown when an unknown or unhandled issue occurs."
                )
            case .validationFailed:
                return String(
                    localized: "Invalid Fields",
                    comment: "Error title shown when user input fails validation, such as missing or incorrect form fields."
                )
            case .networkError:
                return String(
                    localized: "Network Error",
                    comment: "Error title shown when there is no internet connection or the network request cannot be completed."
                )
        }
    }
    
    /// A detailed, localised description of the error for display to the user.
    public var errorDescription: String? {
        switch self {
            case .badRequest:
                return String(
                    localized: "The request was invalid. Please check the form and try again.",
                    comment: "Detailed error message shown when the user's request cannot be processed due to invalid input or parameters."
                )
                
            case .unauthorized:
                return String(
                    localized: "You’re not authorised to perform this action. Please log in and try again.",
                    comment: "Detailed error message shown when the user attempts an action that requires authentication or higher privileges."
                )
                
            case .serverError:
                return String(
                    localized: "Something went wrong on our end. Please try again later.",
                    comment: "Detailed error message shown when the server encounters an internal problem or returns an unexpected response."
                )
                
            case .unexpectedError:
                return String(
                    localized: "An unexpected error occurred. Please try again or contact support.",
                    comment: "Detailed error message shown when an unknown or unhandled issue occurs."
                )
                
            case .validationFailed(let invalidFields):
                let fieldList = invalidFields
                    .map { "• \($0.label)" }
                    .sorted()
                    .joined(separator: "\n")
                
                let baseMessage = String(
                    localized: "Some fields need to be corrected:",
                    comment: "Introductory error message shown before listing which user input fields failed validation."
                )
                return "\(baseMessage)\n\n\(fieldList)"
                
            case .networkError(let error):
                let baseMessage = error.code.friendlyDescription
                let additionalInfo = String(
                    localized: "If this keeps happening, please contact us.",
                    comment: "Additional suggestion shown after a network error, encouraging the user to reach out for support."
                )
                return "\(baseMessage)\n\n\(additionalInfo)"
        }
    }
}
