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
}

extension FormResponse: LocalizedError {
    
    /// A short, localised title for the error, suitable for display in UI alerts.
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
        }
    }
    
    /// A detailed, localised description of the error, suitable for presenting to the user.
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
        }
    }
}
