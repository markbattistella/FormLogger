//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

extension URLError.Code {

    /// A user-friendly description for each `URLError.Code`, suitable for displaying in UI error
    /// messages.
    ///
    /// This maps low-level networking error codes to more understandable explanations for end
    /// users. For all unhandled cases, a generic fallback message is provided.
    internal var friendlyDescription: String {
        switch self {
            case .notConnectedToInternet:
                return "You're not connected to the internet."

            case .timedOut:
                return "The request timed out. Please try again."

            case .cannotFindHost:
                return "We couldn't find the server. The address may be incorrect."

            case .cannotConnectToHost:
                return "We couldn’t connect to the server. It might be temporarily unavailable."

            case .networkConnectionLost:
                return "The connection was lost. Please check your internet and try again."

            case .dnsLookupFailed:
                return "We couldn’t resolve the server address. Please check your connection."

            case .badURL:
                return "The link appears to be invalid."

            case .dataNotAllowed:
                return "Mobile data is turned off or restricted."

            case .secureConnectionFailed:
                return "We couldn't establish a secure connection."

            case .badServerResponse:
                return "The server returned an unexpected response. Please try again later."

            default:
                return "A network error occurred. Please try again."
        }
    }
}
