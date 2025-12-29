//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

extension URLError.Code {

    /// A user-friendly description suitable for displaying networking errors in the UI.
    ///
    /// This property maps low-level `URLError.Code` values to clear, human-readable messages that
    /// can be safely shown to end users. For any unhandled error codes, a generic fallback
    /// message is returned.
    internal var friendlyDescription: String {
        switch self {
            case .notConnectedToInternet:
                return String(
                    localized: "You're not connected to the internet.",
                    bundle: .module,
                    comment: "Error shown when there is no internet connection"
                )

            case .timedOut:
                return String(
                    localized: "The request timed out. Please try again.",
                    bundle: .module,
                    comment: "Error shown when a network request times out"
                )

            case .cannotFindHost:
                return String(
                    localized: "We couldn't find the server. The address may be incorrect.",
                    bundle: .module,
                    comment: "Error shown when the host cannot be resolved"
                )

            case .cannotConnectToHost:
                return String(
                    localized: "We couldn't connect to the server. It might be temporarily unavailable.",
                    bundle: .module,
                    comment: "Error shown when a connection to the host fails"
                )

            case .networkConnectionLost:
                return String(
                    localized: "The connection was lost. Please check your internet and try again.",
                    bundle: .module,
                    comment: "Error shown when the network connection drops"
                )

            case .dnsLookupFailed:
                return String(
                    localized: "We couldn't resolve the server address. Please check your connection.",
                    bundle: .module,
                    comment: "Error shown when DNS lookup fails"
                )

            case .badURL:
                return String(
                    localized: "The link appears to be invalid.",
                    bundle: .module,
                    comment: "Error shown when a URL is malformed"
                )

            case .dataNotAllowed:
                return String(
                    localized: "Mobile data is turned off or restricted.",
                    bundle: .module,
                    comment: "Error shown when mobile data usage is not permitted"
                )

            case .secureConnectionFailed:
                return String(
                    localized: "We couldn't establish a secure connection.",
                    bundle: .module,
                    comment: "Error shown when a secure network connection fails"
                )

            case .badServerResponse:
                return String(
                    localized: "The server returned an unexpected response. Please try again later.",
                    bundle: .module,
                    comment: "Error shown when the server response is invalid"
                )

            default:
                return String(
                    localized: "A network error occurred. Please try again.",
                    bundle: .module,
                    comment: "Fallback error message for unknown network errors"
                )
        }
    }
}
