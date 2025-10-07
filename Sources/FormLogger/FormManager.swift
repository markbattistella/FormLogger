//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import Observation

/// An observable class responsible for managing the lifecycle and state of a form submission.
///
/// `FormManager` handles user input, progress tracking, validation errors, and integration
/// with the configured logging and repository systems. It supports UI binding through observation.
@Observable
public final class FormManager {
    
    // MARK: - Public Properties
    
    /// The current input provided by the user.
    public var userInput: UserFormInput
    
    /// The type of form being submitted (e.g. feedback, support).
    public var formType: FormType
    
    /// Determines whether contact fields should be included and validated.
    public var allowContact: Bool
    
    /// Indicates whether logs should be collected and attached to the form.
    public var shouldCollectLogs: Bool
    
    // MARK: - Internal State
    
    /// Logger instance used for capturing form-related logs and diagnostics.
    private let logger = SimpleLogger(category: .formSubmission)
    
    /// The current progress state of the form (e.g. submitting, completed).
    private var progressState: ProgressState
    
    /// Configuration object providing environment-specific behaviour and dependencies.
    private var config: FormConfiguration

    /// A dictionary of validation errors keyed by form field, updated after validation.
    public private(set) var fieldErrors: [FormField: String]
    
    // MARK: - Init
    
    /// Creates a new instance of `FormManager`.
    ///
    /// - Parameters:
    ///   - formType: The type of form being submitted.
    ///   - configuration: The configuration used to control form behaviour and dependencies.
    public init(
        formType: FormType,
        configuration: FormConfiguration
    ) {
        self.formType = formType
        self.config = configuration
        self.userInput = .default
        self.allowContact = true
        self.shouldCollectLogs = true
        self.progressState = .idle
        self.fieldErrors = [:]
    }
}

// MARK: - Computed Helpers

extension FormManager {
    
    /// Indicates whether the form is currently being processed (e.g. submitting or clearing).
    ///
    /// Returns `true` when the form is in any state other than `.idle`.
    public var isProcessing: Bool {
        progressState != .idle
    }
    
    /// Returns `true` if the current user input passes validation checks.
    ///
    /// Internally calls `validateFormData()` and checks that there are no validation errors.
    public var isFormValid: Bool {
        validateFormData().isEmpty
    }
    
    /// The maximum number of characters allowed in form input fields.
    ///
    /// This value is retrieved from the injected `FormConfiguration`.
    public var characterLimit: Int {
        config.characterLimit
    }
    
    /// A numeric value representing the current progress of the form process.
    ///
    /// Useful for visual progress indicators like progress bars.
    /// Value ranges from `0.0` (idle) to `1.0` (completed).
    public var currentProgress: Double {
        progressState.progress
    }
    
    /// A human-readable description of the current progress state.
    ///
    /// For example: "Submitting form", "Clearing form in 3...", or "Done".
    public var currentProgressLabel: String {
        progressState.description
    }
}

// MARK: - Validation

extension FormManager {
    
    /// Validates the current user input and returns a set of fields that failed validation.
    ///
    /// This method checks for empty or improperly formatted fields, depending on the current
    /// configuration. If `allowContact` is `true`, contact name and email are also validated.
    ///
    /// - Returns: A set of `FormField` cases that contain invalid input.
    private func validateFormData() -> Set<FormField> {
        var errors = Set<FormField>()
        var newErrors: [FormField: String] = [:]
        
        // Validate title
        if userInput.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.insert(.title)
            newErrors[.title] = FormField.title.errorMessage
        }
        
        // Validate message
        if userInput.message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.insert(.message)
            newErrors[.message] = FormField.message.errorMessage
        }
        
        // Validate contact details if required
        if allowContact {
            let contact = userInput.contact
            
            if contact.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                errors.insert(.contactName)
                newErrors[.contactName] = FormField.contactName.errorMessage
            }
            
            let email = contact.email.trimmingCharacters(in: .whitespacesAndNewlines)
            if email.isEmpty || !isValidEmail(email) {
                errors.insert(.contactEmail)
                newErrors[.contactEmail] = FormField.contactEmail.errorMessage
            }
        }
        
        // Update public-facing field error dictionary
        fieldErrors = newErrors
        return errors
    }
    
    /// Clears the validation error for a specific field.
    ///
    /// - Parameter field: The `FormField` to remove from the current error set.
    public func clearError(for field: FormField) {
        fieldErrors[field] = nil
    }
    
    /// Clears all validation errors from the current form state.
    public func clearAllErrors() {
        fieldErrors = [:]
    }
    
    /// Validates an email address using a basic regular expression.
    ///
    /// - Parameter email: The email string to validate.
    /// - Returns: `true` if the email is valid, otherwise `false`.
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,12}$"
        return NSPredicate(format: "SELF MATCHES[c] %@", regex).evaluate(with: email)
    }
}

// MARK: - Form Submission

extension FormManager {
    
    /// Submits the form asynchronously, handling validation, optional log collection, network
    /// request construction, and response handling.
    ///
    /// - Throws: A `FormResponse` error if validation fails, a network issue occurs, or the
    /// server responds with an error.
    @MainActor
    public func submit() async throws {
        
        // Start submission flow
        logger.info("Starting form submission")
        self.progressState = .starting

        // Give SwiftUI a chance to re-render before validation/logging
        await Task.yield()

        // Validate input before proceeding
        let validationErrors = validateFormData()
        guard validationErrors.isEmpty else {
            let mappedErrors = validationErrors.map(\.rawValue).joined(separator: ", ")
            logger.error("Form validation failed: \(mappedErrors)")
            self.progressState = .idle
            throw FormResponse.validationFailed(invalidFields: validationErrors)
        }
        
        // Clear any old validation errors
        self.fieldErrors = [:]
        self.progressState = .fetchingLog
        
        var logData = ""
        
        // Conditionally fetch logs if enabled
        if shouldCollectLogs {
            logger.info("Collecting logs")
            try await config.loggerManager.fetchLogEntries()
            logData = config.loggerManager.exportLogs(as: .log)
            logger.info("Logs collected: \(logData.count) characters")
        } else {
            logger.info("Log collection skipped by user")
        }
        
        // Resolve repository based on form type
        let repo = config.repository.getRepository(for: formType)
        
        // Construct the request body
        let requestBody = FormRequestBody(
            title: userInput.title,
            message: userInput.message,
            repository: repo,
            label: formType.rawValue,
            contact: allowContact ? userInput.contact : nil,
            customMetaData: config.customMetadata
        )
        
        let message = "Submitting form to \(config.apiURL.absoluteString) for repo '\(repo)' with label '\(formType.rawValue)'"
        logger.info("\(message, privacy: .public)")
        self.progressState = .submitting
        
        // Attempt submission and handle response
        do {
            let (_, response) = try await makeMultipartRequest(
                to: config.apiURL,
                requestBody: requestBody,
                logData: logData
            )
            
            try await handleResponse(response)
            logger.info("Form submission successful: HTTP \(response.statusCode)")
            self.progressState = .idle
            
        } catch let urlError as URLError {
            
            // Handle known network errors
            logger.error("Network error: \(urlError.code.rawValue) – \(urlError.localizedDescription, privacy: .public)")
            self.progressState = .idle
            throw FormResponse.networkError(urlError)
            
        } catch {
            
            // Handle all other unexpected errors
            logger.error("Form submission failed: \(String(describing: error))")
            self.progressState = .idle
            throw error
        }
    }
}

// MARK: - Multipart Form

extension FormManager {
    
    /// Constructs and sends a multipart HTTP POST request containing the form data and optional
    /// logs.
    ///
    /// - Parameters:
    ///   - url: The endpoint to which the form will be submitted.
    ///   - requestBody: The structured data payload representing the form content.
    ///   - logData: Optional log string to attach as a `.gz` file.
    /// - Returns: A tuple containing the response data and the HTTP response object.
    /// - Throws: An error if encoding or the request fails, or if the response is invalid.
    @MainActor
    private func makeMultipartRequest(
        to url: URL,
        requestBody: FormRequestBody,
        logData: String
    ) async throws -> (Data, HTTPURLResponse) {
        
        logger.info("Constructing multipart request for submission to \(url.absoluteString, privacy: .sensitive)")
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Set content type for multipart
        let boundary = UUID().uuidString
        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )
        
        // Encode the form data and logs into multipart format
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
        
        logger.info("Multipart request constructed with body size \(httpBody.count) bytes")
        
        // Send the request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // Validate the HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Server response was not a valid HTTPURLResponse")
            throw URLError(.badServerResponse)
        }
        
        logger.info("Received HTTP response with status code \(httpResponse.statusCode)")
        return (data, httpResponse)
    }
    
    /// Builds the HTTP multipart body containing the form data (as JSON) and optional logs
    /// (as `.gz`).
    ///
    /// - Parameters:
    ///   - boundary: The boundary string for separating parts in the multipart payload.
    ///   - requestBody: The structured form data to be encoded as JSON.
    ///   - logs: A plain-text log string, optionally included as a compressed attachment.
    /// - Returns: A `Data` object representing the full multipart HTTP body.
    /// - Throws: An error if JSON encoding or log compression fails.
    private func createMultipartBody(
        boundary: String,
        requestBody: FormRequestBody,
        logs: String
    ) throws -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        let logFilename = "log-\(Date.now.filenameISO8601).log"
        
        // Encode the request body as JSON
        let jsonData = try JSONEncoder().encode(requestBody)
        logger.info("Encoded request body to JSON successfully, size: \(jsonData.count) bytes")
        
        // Add JSON part
        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"requestBody\"\(lineBreak)")
        body.append("Content-Type: application/json\(lineBreak)\(lineBreak)")
        body.append(jsonData)
        body.append(lineBreak)
        
        // Add compressed log file if logs are present
        if !logs.isEmpty {
            let compressedLogs = try logs.data(using: .utf8)?.gzipped() ?? Data()
            if !compressedLogs.isEmpty {
                logger.info("Including compressed log file '\(logFilename).gz', size: \(compressedLogs.count) bytes")
                
                body.append("--\(boundary)\(lineBreak)")
                body.append("Content-Disposition: form-data; name=\"logs\"; filename=\"\(logFilename).gz\"\(lineBreak)")
                body.append("Content-Type: application/gzip\(lineBreak)\(lineBreak)")
                body.append(compressedLogs)
                body.append(lineBreak)
            } else {
                logger.warning("Log data was not empty but compression resulted in empty data")
            }
        } else {
            logger.info("No logs included in multipart body")
        }
        
        // Close the multipart body
        body.append("--\(boundary)--\(lineBreak)")
        
        return body
    }
}

// MARK: - Network Results

extension FormManager {
    
    /// Handles the server's HTTP response after form submission.
    ///
    /// Based on the HTTP status code, this method logs relevant information, updates the progress
    /// state, clears the form if configured, or throws an appropriate error.
    ///
    /// - Parameter response: The HTTP response received from the server.
    /// - Throws: A `FormResponse` error for known failure scenarios, or `.unexpectedError` for unknown cases.
    @MainActor
    private func handleResponse(
        _ response: HTTPURLResponse
    ) async throws {
        logger.info("Handling server response, status code: \(response.statusCode)")
        
        switch response.statusCode {
                
            case 200...299:
                logger.info("Form submission successful")
                
                // Check if the form should be cleared
                if config.shouldClearForm {
                    logger.info("Clearing form after successful submission (delay: \(self.config.clearFormDelay.formatted()))")
                    
                    let totalDuration = config.clearFormDelay
                    let steps = 10
                    let stepDuration = totalDuration / steps
                    
                    // Gradually update progress state with countdown
                    for step in (1...steps).reversed() {
                        let secondsLeft = max(1, Int((Double(step) / Double(steps)) * Double(totalDuration.components.seconds)))
                        progressState = .clearingForm(timeRemaining: secondsLeft)
                        try? await Task.sleep(for: stepDuration)
                    }
                    
                    // Reset form to default input state
                    userInput = .default
                }
                
                // Show completed state briefly, then reset
                progressState = .completed
                try? await Task.sleep(for: .seconds(2))
                progressState = .idle

            case 400:
                logger.warning("Form submission failed: bad request (400)")
                throw FormResponse.badRequest
                
            case 401:
                logger.warning("Form submission failed: unauthorized (401)")
                throw FormResponse.unauthorized
                
            case 500:
                logger.error("Form submission failed: server error (500)")
                throw FormResponse.serverError
                
            default:
                logger.error(
                    "Form submission failed: unexpected status code \(response.statusCode, privacy: .public)"
                )
                throw FormResponse.unexpectedError
        }
    }
}

// MARK: - Configuration

extension FormManager {

    /// Updates the form manager’s configuration at runtime.
    ///
    /// Use this method when environment-dependent or dynamically generated settings (such as API
    /// endpoints, metadata, or repository mappings) become available after the manager has been
    /// created.
    ///
    /// - Parameter configuration: A new `FormConfiguration` instance that replaces the manager’s
    /// existing configuration.
    ///
    /// - Note: Updating the configuration does not reset user input or progress state; it only
    /// changes the underlying behaviour and metadata used for future submissions.
    public func updateConfiguration(_ configuration: FormConfiguration) {
        self.config = configuration
    }
}
