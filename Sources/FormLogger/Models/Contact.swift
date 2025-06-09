//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A structure representing a contact with a name and email address.
///
/// Conforms to `Encodable` for easy serialization.
public struct Contact: Encodable {

    /// The full name of the contact.
    public var name: String

    /// The contact's email address.
    public var email: String

    /// Creates a new `Contact` instance.
    ///
    /// - Parameters:
    ///   - name: The contact’s full name.
    ///   - email: The contact’s email address.
    public init(name: String, email: String) {
        self.name = name
        self.email = email
    }
}
