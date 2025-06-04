//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A structure representing the body of a form submission request.
///
/// Contains metadata about the form input, the associated repository, optional contact
/// information, and client details such as app version and OS.
internal struct FormRequestBody: Encodable {

    /// A unique identifier for the form submission.
    internal let id: String

    /// The title of the form submission.
    internal let title: String

    /// The detailed description of the issue or request.
    internal let description: String

    /// The repository associated with the form submission.
    internal let repository: Repository

    /// A label used to categorise or tag the submission.
    internal let label: String

    /// Optional contact information provided by the user.
    internal let contact: Contact?

    /// Metadata about the client app and operating system.
    internal let client: ClientMetadata

    /// Creates a new `FormRequestBody` instance.
    ///
    /// - Parameters:
    ///   - title: The title of the form submission.
    ///   - description: A description of the submission.
    ///   - repository: The associated `Repository` object.
    ///   - label: A tag or label for categorisation.
    ///   - contact: Optional contact details for follow-up.
    internal init(
        title: String,
        description: String,
        repository: Repository,
        label: String,
        contact: Contact?
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.description = description
        self.repository = repository
        self.label = label
        self.contact = contact
        self.client = ClientMetadata()
    }
}
