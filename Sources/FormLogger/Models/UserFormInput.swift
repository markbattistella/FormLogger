//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A structure representing user-provided input for a form submission.
///
/// Includes the title, description, and optional contact information.
public struct UserFormInput {

    /// The title of the form input, typically a brief summary.
    public let title: String

    /// A detailed description provided by the user.
    public let description: String

    /// Optional contact information for follow-up or identification.
    public let contact: Contact?

    /// Creates a new `UserFormInput` instance.
    ///
    /// - Parameters:
    ///   - title: The summary or headline of the input.
    ///   - description: A more detailed explanation or message.
    ///   - contact: Optional contact details.
    public init(title: String, description: String, contact: Contact?) {
        self.title = title
        self.description = description
        self.contact = contact
    }

    /// A default empty `UserFormInput` instance.
    ///
    /// Useful for initialising forms or resetting user input.
    public static var `default`: UserFormInput {
        UserFormInput(title: "", description: "", contact: nil)
    }
}
