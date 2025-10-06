//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A payload structure representing the body of a form submission request.
///
/// Encoded and sent to the backend, this includes all necessary user input along with repository
/// context and client metadata.
internal struct FormRequestBody: Encodable {
    
    /// A unique identifier for the form submission, auto-generated at initialisation.
    internal let id: String
    
    /// The title or subject of the form.
    internal let title: String
    
    /// The message or main content body of the form.
    internal let message: String
    
    /// The repository related to the submission context.
    internal let repository: Repository
    
    /// A label categorising or tagging the form submission.
    internal let label: String
    
    /// Optional contact information provided by the user.
    internal let contact: Contact?
    
    /// Metadata about the client (e.g. app version, platform, etc.), auto-filled.
    internal let client: ClientMetadata

    /// Optional dictionary of additional key–value metadata supplied by the host app.
    internal let customMetadata: [String : String]?

    /// Creates a new form request body containing message details, client metadata, and optional
    /// custom metadata defined by the host application.
    ///
    /// - Parameters:
    ///   - title: The short title or subject of the submitted form.
    ///   - message: The main message body entered by the user.
    ///   - repository: The repository destination for storing or processing the form data.
    ///   - label: A tag or identifier describing the form type.
    ///   - contact: Optional contact details provided by the user.
    ///   - customMetaData: Optional dictionary of additional metadata to include with the request.
    internal init(
        title: String,
        message: String,
        repository: Repository,
        label: String,
        contact: Contact?,
        customMetaData: [String: String]? = nil
    ) {
        self.id = UUID().uuidString
        self.title = title
        self.message = message
        self.repository = repository
        self.label = label
        self.contact = contact
        self.client = ClientMetadata()
        self.customMetadata = customMetaData
    }
}
