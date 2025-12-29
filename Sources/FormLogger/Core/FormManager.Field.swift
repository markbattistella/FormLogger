//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

extension FormManager {

    /// Represents an individual field within the form.
    ///
    /// `Field` is used to identify form inputs for validation, error reporting, and UI labelling
    /// purposes.
    public enum Field: String {

        /// The form title field.
        case title

        /// The main message or body field.
        case message

        /// The contact name field.
        case contactName

        /// The contact email address field.
        case contactEmail

        /// A localized, user-facing label for the field.
        ///
        /// This value is typically displayed alongside the corresponding input control in the UI.
        internal var label: String {
            switch self {
                case .title:
                    String(
                        localized: "Title",
                        bundle: .module
                    )
                case .message:
                    String(
                        localized: "Message",
                        bundle: .module
                    )
                case .contactName:
                    String(
                        localized: "Contact name",
                        bundle: .module
                    )
                case .contactEmail:
                    String(
                        localized: "Contact email",
                        bundle: .module
                    )
            }
        }

        /// The default localized validation error message for the field.
        ///
        /// This message is used when validation fails and no custom error message is provided.
        internal var errorMessage: String {
            switch self {
                case .title:
                    String(
                        localized: "Title is required.",
                        bundle: .module
                    )
                case .message:
                    String(
                        localized: "Message is required.",
                        bundle: .module
                    )
                case .contactName:
                    String(
                        localized: "Contact name is required.",
                        bundle: .module
                    )
                case .contactEmail:
                    String(
                        localized: "Enter a valid email address.",
                        bundle: .module
                    )
            }
        }
    }
}
