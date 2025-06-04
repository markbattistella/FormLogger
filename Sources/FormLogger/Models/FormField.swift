//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents the individual fields of a form that may require validation or user input.
///
/// Conforms to `Hashable` for use in sets and dictionaries, and `Sendable` for safe use across
/// concurrency boundaries.
public enum FormField: Hashable, Sendable {

    /// The title field of the form.
    case title

    /// The description field of the form.
    case description

    /// The contact name field of the form.
    case contactName

    /// The contact email field of the form.
    case contactEmail
}

extension FormField {
    var errorMessage: String {
        switch self {
            case .title:
                return "Please enter a title."

            case .description:
                return "Please provide a description."

            case .contactName:
                return "Please enter your name."

            case .contactEmail:
                return "Please provide a valid email address."
        }
    }
}
