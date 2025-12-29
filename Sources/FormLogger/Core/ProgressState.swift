//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

extension FormManager {

    /// Represents the current progress state of the form submission lifecycle.
    ///
    /// `ProgressState` models each discrete phase of submission, from idle through completion,
    /// and provides UI-friendly metadata such as display messages and progress values.
    public enum ProgressState: Equatable {

        /// The form is idle and no operation is currently in progress.
        case idle

        /// Diagnostic logs are being exported prior to submission.
        case exportingLogs

        /// The form payload is being submitted to the backend service.
        case submitting

        /// The server response is being processed after submission.
        case processingResponse

        /// The form is waiting to be cleared, with a countdown timer.
        ///
        /// - Parameter timeRemaining: The number of seconds remaining before the form is cleared.
        case clearingForm(timeRemaining: Int)

        /// The submission process has completed successfully.
        case completed

        /// A localized, user-facing message describing the current state.
        ///
        /// This value is typically displayed in the UI to inform the user of the current
        /// submission phase.
        public var displayMessage: String {
            switch self {
                case .idle:
                    return ""
                case .exportingLogs:
                    return String(localized: "Exporting logs…", bundle: .module)
                case .submitting:
                    return String(localized: "Submitting…", bundle: .module)
                case .processingResponse:
                    return String(localized: "Processing response…", bundle: .module)
                case .clearingForm(let timeRemaining):
                    return String(localized: "Form will clear in \(timeRemaining)s…", bundle: .module)
                case .completed:
                    return String(localized: "Submitted", bundle: .module)
            }
        }

        /// A normalised progress value representing the current state.
        ///
        /// This value ranges from `0.0` to `1.0` and can be used to drive progress indicators
        /// in the UI.
        public var progress: Double {
            switch self {
                case .idle:
                    return 0.0
                case .exportingLogs:
                    return 0.2
                case .submitting:
                    return 0.6
                case .processingResponse:
                    return 0.8
                case .clearingForm:
                    return 0.9
                case .completed:
                    return 1.0
            }
        }
    }
}
