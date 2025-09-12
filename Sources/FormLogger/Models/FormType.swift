//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents the type of form being submitted by the user.
///
/// Used to categorise submissions into bugs, feature requests, or general feedback.
public enum FormType: String, Codable, CaseIterable {

    /// A form for reporting a bug.
    case bug

    /// A form for requesting a new feature.
    case feature

    /// A form for submitting general feedback.
    case feedback
}

extension FormType: CustomStringConvertible {

    /// A user-friendly description of the form type.
    ///
    /// Used for display in UI elements such as buttons or headings.
    public var description: String {
        "\(Self.self).\(rawValue)"
    }
}

extension FormType: CustomLocalizedStringResourceConvertible{

    /// A localised string resource describing the form type.
    ///
    /// Provides UI-ready text for different submission categories.
    public var localizedStringResource: LocalizedStringResource {
        switch self {
            case .bug: return "Report a bug"
            case .feature: return "Request a feature"
            case .feedback: return "Send feedback"
        }
    }
}
