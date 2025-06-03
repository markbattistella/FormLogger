//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents the various states of progress during a form submission workflow.
///
/// Provides a textual description and a numeric progress value for each state, which can be used
/// to update UI components like progress bars or status messages.
internal enum ProgressState: CustomStringConvertible {

    /// The initial idle state before any action has started.
    case idle

    /// Indicates the process is starting.
    case starting

    /// Indicates logs are currently being fetched.
    case fetchingLog

    /// Indicates the form is being submitted.
    case submitting

    /// The process has completed successfully.
    case completed

    /// A human-readable description of the current state.
    internal var description: String {
        switch self {
            case .idle: return "Idle"
            case .starting: return "Starting"
            case .fetchingLog: return "Fetching logs"
            case .submitting: return "Submitting form"
            case .completed: return "Done"
        }
    }

    /// A numeric representation of progress for the current state, ranging from 0.0 to 1.0.
    ///
    /// Useful for driving progress indicators in the UI.
    internal var progress: Double {
        switch self {
            case .idle: return 0.0
            case .starting: return 0.05
            case .fetchingLog: return 0.45
            case .submitting: return 0.75
            case .completed: return 1.0
        }
    }
}
