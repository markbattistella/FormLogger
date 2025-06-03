//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// Represents a validation error that occurs when submitting a form.
///
/// Contains a set of fields that failed validation. Conforms to the `Error` protocol to allow
/// usage in error handling.
public struct FormValidationError: Error {

    /// The set of form fields that did not pass validation.
    public let invalidFields: Set<FormField>

    /// Creates a new `FormValidationError` with the given invalid fields.
    ///
    /// - Parameter invalidFields: A set of `FormField` values indicating which fields are invalid.
    public init(invalidFields: Set<FormField>) {
        self.invalidFields = invalidFields
    }
}
