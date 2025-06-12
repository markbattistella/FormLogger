//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents the individual fields in a form submission.
public enum FormField: String, Hashable, Sendable {

    /// The title field of the form.
    case title

    /// The main message or body content field.
    case message

    /// The contact name field.
    case contactName = "Contact Name"

    /// The contact email address field.
    case contactEmail = "Contact Email"
}

extension FormField {

    /// A user-facing label derived from the raw value of the enum case.
    ///
    /// This is typically used in the UI to display field names in a readable format.
    internal var label: String {
        self.rawValue.capitalized
    }

    /// A field-specific validation error message.
    ///
    /// Returned when a form field fails validation, used to inform the user what’s wrong.
    internal var errorMessage: String {
        switch self {
            case .title:
                return "Please enter a title."

            case .message:
                return "Please provide a message."

            case .contactName:
                return "Please enter your name."

            case .contactEmail:
                return "Please provide a valid email address."
        }
    }
}
