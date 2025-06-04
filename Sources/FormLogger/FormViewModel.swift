//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import Observation

/// A view model that manages user input, form validation, log collection, and submission of a
/// support or feedback form.
///
/// This class handles the full form submission lifecycle and provides state for UI updates via
/// progress indicators and validation flags.
@Observable
public final class FormViewModel {
    
    // MARK: - Public Properties
    
    /// The user-provided form input.
    public var userInput: UserFormInput
    
    /// The type of form being submitted (e.g., bug, feature, feedback).
    public var formType: FormType
    
    /// Indicates whether the user is allowed to include contact details.
    public var allowContact: Bool
    
    // MARK: - Internal State
    
    /// The current state of form submission progress.
    private(set) var progressState: ProgressState
    
    /// The form configuration used for this view model instance.
    private let config: FormConfiguration
    
    // MARK: - Init
    
    /// Creates a new `FormViewModel` instance.
    ///
    /// - Parameters:
    ///   - formType: The type of form being submitted.
    ///   - configuration: Configuration data such as API URL, logging, and repository targets.
    public init(
        formType: FormType,
        configuration: FormConfiguration
    ) {
        self.formType = formType
        self.config = configuration
        self.userInput = .default
        self.allowContact = true
        self.progressState = .idle
    }
    
    // MARK: - Computed Helpers
    
    /// Indicates whether the form submission process is currently active.
    public var isProcessing: Bool {
        progressState != .idle
    }
    
    /// Indicates whether the current form input is valid.
    public var isFormValid: Bool {
        validateFormData().isEmpty
    }
    
    /// The character limit allowed for user input fields.
    public var characterLimit: Int {
        config.characterLimit
    }
    
    /// The current numeric progress of the form submission.
    public var currentProgress: Double {
        progressState.progress
    }
    
    /// A human-readable label describing the current progress state.
    public var currentProgressLabel: String {
        progressState.description
    }
}

// MARK: - Validation

extension FormViewModel {
    
    /// Validates the current user input and returns a set of invalid fields.
    ///
    /// - Returns: A set of `FormField` values representing fields that failed validation.
    private func validateFormData() -> Set<FormField> {
        var errors = Set<FormField>()
        
        if userInput.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.insert(.title)
        }
        
        if userInput.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.insert(.description)
        }
        
        if allowContact {
            guard let contact = userInput.contact else {
                errors.insert(.contactName)
                errors.insert(.contactEmail)
                return errors
            }
            
            if contact.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.insert(.contactName)
            }
            
            let email = contact.email.trimmingCharacters(in: .whitespacesAndNewlines)
            if email.isEmpty || !isValidEmail(email) {
                errors.insert(.contactEmail)
            }
        }
        
        return errors
    }
    
    /// Checks whether the given email address appears valid using a simple regex.
    ///
    /// - Parameter email: The email string to validate.
    /// - Returns: A Boolean indicating whether the email is valid.
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,12}$"
        return NSPredicate(format: "SELF MATCHES[c] %@", regex).evaluate(with: email)
    }
}

// MARK: - Form Submission

extension FormViewModel {
    
    /// Submits the form, collecting logs, validating input, and handling response.
    ///
    /// - Returns: A `FormResponse` indicating success or the type of failure.
    /// - Throws: `FormValidationError` if validation fails, or other `FormResponse` errors.
    @MainActor
    public func submit() async throws -> FormResponse {
        
        progressState = .starting
        
        let validationErrors = validateFormData()
        guard validationErrors.isEmpty else {
            progressState = .idle
            throw FormValidationError(invalidFields: validationErrors)
        }
        
        progressState = .fetchingLog
        try await config.loggerManager.fetchLogEntries()
        let logData = config.loggerManager.exportLogs(as: .log)
        
        let repo = config.repository.getRepository(for: formType)
        
        let requestBody = FormRequestBody(
            title: userInput.title,
            description: userInput.description,
            repository: repo,
            label: formType.rawValue,
            contact: allowContact ? userInput.contact : nil
        )
        
        progressState = .submitting
        
        do {
            let (_, response) = try await makeMultipartRequest(
                to: config.apiURL,
                requestBody: requestBody,
                logData: logData
            )
            
            try await handleResponse(response)
            progressState = .idle
            return .successMessage
            
        } catch {
            self.progressState = .idle
            throw error
        }
    }
}

// MARK: - Multipart Form

extension FormViewModel {
    
    /// Creates and sends a multipart HTTP request containing the form data and logs.
    ///
    /// - Parameters:
    ///   - url: The target URL for the request.
    ///   - requestBody: The form data to submit.
    ///   - logData: The logs to attach, as a string.
    /// - Returns: A tuple containing the response data and the HTTP response.
    @MainActor
    private func makeMultipartRequest(
        to url: URL,
        requestBody: FormRequestBody,
        logData: String
    ) async throws -> (Data, HTTPURLResponse) {
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        
        let httpBody = try createMultipartBody(
            boundary: boundary,
            requestBody: requestBody,
            logs: logData
        )
        request.httpBody = httpBody
        request.setValue(
            "\(httpBody.count)",
            forHTTPHeaderField: "Content-Length"
        )
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        return (data, httpResponse)
    }
    
    /// Creates the multipart body containing encoded form data and compressed logs.
    ///
    /// - Parameters:
    ///   - boundary: The multipart boundary string.
    ///   - requestBody: The encoded form request body.
    ///   - logs: The raw log text to compress and include.
    /// - Returns: A `Data` object representing the complete multipart body.
    private func createMultipartBody(
        boundary: String,
        requestBody: FormRequestBody,
        logs: String
    ) throws -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        let logFilename = "log-\(Date.now.filenameISO8601).log"
        
        let jsonData = try JSONEncoder().encode(requestBody)
        
        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"requestBody\"\(lineBreak)")
        body.append("Content-Type: application/json\(lineBreak)\(lineBreak)")
        body.append(jsonData)
        body.append(lineBreak)
        
        let compressedLogs = try logs.data(using: .utf8)?.gzipped() ?? Data()
        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"logs\"; filename=\"\(logFilename).gz\"\(lineBreak)")
        body.append("Content-Type: application/gzip\(lineBreak)\(lineBreak)")
        body.append(compressedLogs)
        body.append(lineBreak)
        
        body.append("--\(boundary)--\(lineBreak)")
        return body
    }
}

// MARK: - Network Results

extension FormViewModel {
    
    /// Handles the server response after submitting the form.
    ///
    /// - Parameter response: The HTTP response received.
    /// - Throws: A `FormResponse` error if the status code indicates failure.
    @MainActor
    private func handleResponse(_ response: HTTPURLResponse) async throws {
        switch response.statusCode {
            case 200...299:
                if config.shouldClearForm {
                    try? await Task.sleep(for: .seconds(config.clearFormDelay))
                    userInput = .default
                }
                progressState = .completed
            case 400:
                throw FormResponse.badRequest
            case 401:
                throw FormResponse.unauthorized
            case 500:
                throw FormResponse.serverError
            default:
                throw FormResponse.unexpectedError
        }
    }
}
