//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A payload representing a form submission.
///
/// This type encapsulates all information required to submit a form, including user-provided
/// content, repository context, and automatically collected client metadata. It is intended to
/// be encoded and sent to a backend service.
internal struct FormPayload: Encodable {

    /// A unique identifier for the form submission.
    internal let id: String

    /// The title of the form submission.
    internal let title: String

    /// The main message or body of the form submission.
    internal let message: String

    /// The name of the contact submitting the form, if provided.
    internal let contactName: String?

    /// The email address of the contact submitting the form, if provided.
    internal let contactEmail: String?

    /// The target GitHub repository associated with the submission.
    internal let repository: Repository.Github

    /// A label applied to the submission for categorisation or triage.
    internal let label: String

    /// Metadata describing the client application and runtime environment.
    internal let clientMetadata: ClientMetadata

    /// Additional custom metadata supplied with the submission.
    internal let customMetadata: [String : String]?

    /// Creates a new `FormPayload` with the provided form details.
    ///
    /// - Parameters:
    ///   - title: The title of the form submission.
    ///   - message: The main message or body of the submission.
    ///   - contactName: The name of the contact submitting the form.
    ///   - contactEmail: The email address of the contact submitting the form.
    ///   - repository: The GitHub repository associated with the submission.
    ///   - label: A label applied to the submission.
    ///   - customMetadata: Optional additional key-value metadata.
    internal init(
        title: String,
        message: String,
        contactName: String?,
        contactEmail: String?,
        repository: Repository.Github,
        label: String,
        customMetadata: [String : String]? = nil
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.message = message
        self.contactName = contactName
        self.contactEmail = contactEmail
        self.repository = repository
        self.label = label
        self.clientMetadata = ClientMetadata()
        self.customMetadata = customMetadata
    }
}
