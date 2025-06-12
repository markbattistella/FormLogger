//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents the different stages of a form's progress lifecycle, from idle state to final
/// completion.
internal enum ProgressState: CustomStringConvertible {

    /// The form is idle, with no active operation.
    case idle

    /// The form process is just starting.
    case starting

    /// The form is currently fetching logs (e.g., from local storage or a server).
    case fetchingLog

    /// The form is being submitted to the server.
    case submitting

    /// The form has been submitted and is waiting to be cleared, with a countdown.
    ///
    /// - Parameter timeRemaining: Seconds remaining before the form is reset.
    case clearingForm(timeRemaining: Int)

    /// The entire form process has completed.
    case completed
}

extension ProgressState {

    /// A user-friendly string description of the current progress state.
    internal var description: String {
        switch self {
            case .idle:
                return "Idle"

            case .starting: 
                return "Starting"

            case .fetchingLog:
                return "Fetching logs"

            case .submitting:
                return "Submitting form"

            case .clearingForm(let timeRemaining):
                return "Clearing form in \(timeRemaining)..."

            case .completed:
                return "Done"
        }
    }

    /// A numeric representation of progress for use in visual progress indicators.
    ///
    /// - Returns: A value between `0.0` and `1.0` representing the current progress stage.
    internal var progress: Double {
        switch self {
            case .idle: return 0.0
            case .starting: return 0.05
            case .fetchingLog: return 0.45
            case .submitting: return 0.75
            case .clearingForm: return 0.95
            case .completed: return 1.0
        }
    }
}

extension ProgressState: Equatable {

    /// Equality check between two `ProgressState` values, ignoring associated values.
    /// This ensures `clearingForm` states are considered equal regardless of countdown time.
    internal static func == (lhs: ProgressState, rhs: ProgressState) -> Bool {
        switch (lhs, rhs) {
            case (.idle, .idle),
                (.starting, .starting),
                (.fetchingLog, .fetchingLog),
                (.submitting, .submitting),
                (.completed, .completed):
                return true
            case (.clearingForm, .clearingForm):
                return true
            default:
                return false
        }
    }
}
