//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents the type of form being submitted by the user.
///
/// Used to categorise submissions into bugs, feature requests, or general feedback.
public enum FormType: String, Codable, CaseIterable, CustomStringConvertible {

    /// A form for reporting a bug.
    case bug

    /// A form for requesting a new feature.
    case feature

    /// A form for submitting general feedback.
    case feedback

    /// A lowercase string label representing the form type.
    ///
    /// Useful for identifiers, analytics, or tagging.
    public var label: String {
        rawValue.lowercased()
    }

    /// A user-friendly description of the form type.
    ///
    /// Used for display in UI elements like buttons or headings.
    public var description: String {
        switch self {
            case .bug: return "Report a bug"
            case .feature: return "Request a feature"
            case .feedback: return "Send feedback"
        }
    }
}
