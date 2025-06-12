//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A model representing user-provided input for a form submission.
///
/// This struct captures what the user enters in the form UI and can later be validated or
/// transformed into a request body for backend submission.
public struct UserFormInput {

    /// The title or subject entered by the user.
    public var title: String

    /// The main message content entered by the user.
    public var message: String

    /// The user's contact details (name and email).
    public var contact: Contact

    /// Creates a new instance of `UserFormInput`.
    ///
    /// - Parameters:
    ///   - title: The form's title input.
    ///   - message: The form's message body.
    ///   - contact: The user's contact information.
    public init(
        title: String,
        message: String,
        contact: Contact
    ) {
        self.title = title
        self.message = message
        self.contact = contact
    }

    /// A default (empty) form input used to initialise the form UI or reset state.
    public static var `default`: UserFormInput {
        UserFormInput(
            title: "",
            message: "",
            contact: .init(name: "", email: "")
        )
    }
}
