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
public struct FormRequestBody: Encodable {
    
    /// A unique identifier for the form submission.
    public let id: String
    
    /// The title of the form submission.
    public let title: String
    
    /// The detailed description of the issue or request.
    public let description: String
    
    /// The repository associated with the form submission.
    public let repository: Repository
    
    /// A label used to categorise or tag the submission.
    public let label: String
    
    /// Optional contact information provided by the user.
    public let contact: Contact?
    
    /// Metadata about the client app and operating system.
    public let client: ClientMetadata
    
    /// Creates a new `FormRequestBody` instance.
    ///
    /// - Parameters:
    ///   - title: The title of the form submission.
    ///   - description: A description of the submission.
    ///   - repository: The associated `Repository` object.
    ///   - label: A tag or label for categorisation.
    ///   - contact: Optional contact details for follow-up.
    public init(
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
