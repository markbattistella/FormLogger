//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

extension FormManager {

    /// Represents errors that can occur during form submission.
    ///
    /// `FormResponse` maps network and server-side failures to user-facing, localised error
    /// titles and descriptions that are suitable for display in the UI.
    public enum FormResponse: Error, LocalizedError {

        /// The request was rejected due to invalid input or parameters.
        case badRequest

        /// The request failed due to missing or invalid authorisation.
        case unauthorized

        /// The server encountered an internal error.
        case serverError

        /// The server returned an unexpected HTTP status code.
        ///
        /// - Parameter Int: The unrecognised status code returned by the server.
        case unexpectedStatus(Int)

        /// The request failed due to a network-related error.
        ///
        /// - Parameter URLError: The underlying network error.
        case networkError(URLError)

        /// A short, localised title describing the error.
        ///
        /// This value is typically displayed as a headline or alert title to summarise the
        /// failure.
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

                case .unexpectedStatus:
                    return String(
                        localized: "Unexpected Response",
                        comment: "Error title shown when the server returns an unrecognised status code."
                    )

                case .networkError:
                    return String(
                        localized: "Network Error",
                        comment: "Error title shown when there is no internet connection or the network request cannot be completed."
                    )
            }
        }

        /// A detailed, localised description of the error.
        ///
        /// This value provides additional context and guidance to help the user understand the
        /// failure and possible next steps.
        public var errorDescription: String? {
            switch self {
                case .badRequest:
                    return String(
                        localized: "The request was invalid. Please check the form and try again.",
                        comment: "Detailed error message shown when the user's request cannot be processed due to invalid input or parameters."
                    )

                case .unauthorized:
                    return String(
                        localized: "You're not authorised to perform this action. Please log in and try again.",
                        comment: "Detailed error message shown when the user attempts an action that requires authentication or higher privileges."
                    )

                case .serverError:
                    return String(
                        localized: "Something went wrong on our end. Please try again later.",
                        comment: "Detailed error message shown when the server encounters an internal problem or returns an unexpected response."
                    )

                case .unexpectedStatus(let statusCode):
                    return String(
                        localized: "The server returned an unexpected response (code \(statusCode)). Please try again later.",
                        comment: "Detailed error message shown when the server returns an unrecognised HTTP status code."
                    )

                case .networkError(let error):
                    let baseMessage = error.code.friendlyDescription
                    let additionalInfo = String(
                        localized: "If this keeps happening, please contact support.",
                        comment: "Additional suggestion shown after a network error, encouraging the user to reach out for support."
                    )
                    return "\(baseMessage)\n\n\(additionalInfo)"
            }
        }
    }
}
