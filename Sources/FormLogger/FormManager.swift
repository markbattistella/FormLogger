//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import Observation
import SimpleLogger

extension LoggerCategory {

    /// A logger category used for form submission events.
    static let formSubmission = LoggerCategory("FormSubmission")
}

/// A view model that manages user input, form validation, log collection, and submission of a
/// support or feedback form.
///
/// This class handles the full form submission lifecycle and provides state for UI updates via
/// progress indicators and validation flags.
@Observable
public final class FormManager {

    // MARK: - Public Properties

    /// The user-provided form input.
    public var userInput: UserFormInput

    /// The type of form being submitted (e.g., bug, feature, feedback).
    public var formType: FormType

    /// Indicates whether the user is allowed to include contact details.
    public var allowContact: Bool

    /// A Boolean value that determines whether logs should be collected.
    public var shouldCollectLogs: Bool

    // MARK: - Internal State

    /// A logger instance scoped to the form submission category.
    private let logger = SimpleLogger(category: .formSubmission)

    /// The current state of form submission progress.
    private var progressState: ProgressState

    /// The form configuration used for this view model instance.
    private let config: FormConfiguration

    /// A dictionary containing validation error messages for specific form fields.
    public private(set) var fieldErrors: [FormField: String]

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
        self.shouldCollectLogs = true
        self.progressState = .idle
        self.fieldErrors = [:]
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

extension FormManager {

    /// Validates the current user input for all relevant form fields.
    ///
    /// This method checks the required fields—such as title, description, and contact information
    /// for validity. If any field contains  invalid or missing data, it is added to a set of
    /// fields with errors, and a corresponding error message is stored in `fieldErrors`.
    ///
    /// - Returns: A set of `FormField` values representing the fields that failed validation.
    private func validateFormData() -> Set<FormField> {
        var errors = Set<FormField>()
        var newErrors: [FormField: String] = [:]

        // Title
        if userInput.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.insert(.title)
            newErrors[.title] = FormField.title.errorMessage
        }

        // Description
        if userInput.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.insert(.description)
            newErrors[.description] = FormField.description.errorMessage
        }

        // Contact Info
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

        // Log errors
        for (field, message) in newErrors {
            logger.error("Validation failed for: '\(field.rawValue, privacy: .public)': \(message, privacy: .public)")
        }

        fieldErrors = newErrors
        return errors
    }

    /// Clears the error associated with the specified form field.
    ///
    /// Use this method to remove a validation or input error previously
    /// set for a given `FormField`.
    ///
    /// - Parameter field: The form field for which to clear the error.
    public func clearError(for field: FormField) {
        fieldErrors[field] = nil
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

extension FormManager {

    /// Submits the form data asynchronously after validating input and optionally collecting logs.
    ///
    /// This method performs the following steps:
    /// - Validates user input fields.
    /// - Logs any validation failures and throws an error if necessary.
    /// - Optionally collects diagnostic logs if `shouldCollectLogs` is `true`.
    /// - Prepares a request payload with form details.
    /// - Sends a multipart form submission to the configured API endpoint.
    /// - Handles the API response, updating the submission state and logging results.
    ///
    /// - Throws:
    ///   - `FormValidationError` if form validation fails.
    ///   - Any error thrown during log collection, request building, or network communication.
    @MainActor
    public func submit() async throws {

        logger.info("Starting form submission")
        self.progressState = .starting

        let validationErrors = validateFormData()
        guard validationErrors.isEmpty else {
            let message = "Form validation failed: \(validationErrors.map(\.rawValue).joined(separator: ", "))"
            logger.warning("\(message, privacy: .public)")
            self.progressState = .idle
            throw FormValidationError(invalidFields: validationErrors)
        }

        self.fieldErrors = [:]
        self.progressState = .fetchingLog
        var logData = ""

        if shouldCollectLogs {
            logger.info("Collecting logs")
            try await config.loggerManager.fetchLogEntries()
            logData = config.loggerManager.exportLogs(as: .log)
            logger.info("Logs collected: \(logData.count) characters")
        } else {
            logger.info("Log collection skipped by user")
        }

        let repo = config.repository.getRepository(for: formType)

        let requestBody = FormRequestBody(
            title: userInput.title,
            description: userInput.description,
            repository: repo,
            label: formType.rawValue,
            contact: allowContact ? userInput.contact : nil
        )

        let message = "Submitting form to \(config.apiURL.absoluteString) for repo '\(repo)' with label '\(formType.rawValue)'"
        logger.info("\(message, privacy: .public)")
        self.progressState = .submitting

        do {
            let (_, response) = try await makeMultipartRequest(
                to: config.apiURL,
                requestBody: requestBody,
                logData: logData
            )

            try await handleResponse(response)
            logger.info("Form submission successful: HTTP \(response.statusCode)")
            self.progressState = .idle
        } catch {
            logger.error("Form submission failed: \(String(describing: error))")
            self.progressState = .idle
            throw error
        }
    }
}

// MARK: - Multipart Form

extension FormManager {

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

        logger.info("Constructing multipart request for submission to \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let httpBody = try createMultipartBody(
            boundary: boundary,
            requestBody: requestBody,
            logs: logData
        )
        request.httpBody = httpBody
        request.setValue("\(httpBody.count)", forHTTPHeaderField: "Content-Length")

        logger.info("Multipart request constructed with body size \(httpBody.count) bytes")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Server response was not a valid HTTPURLResponse")
            throw URLError(.badServerResponse)
        }

        logger.info("Received HTTP response with status code \(httpResponse.statusCode)")
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
        logger.info("Encoded request body to JSON successfully, size: \(jsonData.count) bytes")

        body.append("--\(boundary)\(lineBreak)")
        body.append("Content-Disposition: form-data; name=\"requestBody\"\(lineBreak)")
        body.append("Content-Type: application/json\(lineBreak)\(lineBreak)")
        body.append(jsonData)
        body.append(lineBreak)

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

        body.append("--\(boundary)--\(lineBreak)")

        return body
    }
}

// MARK: - Network Results

extension FormManager {

    /// Handles the server response after submitting the form.
    ///
    /// - Parameter response: The HTTP response received.
    /// - Throws: A `FormResponse` error if the status code indicates failure.
    @MainActor
    private func handleResponse(_ response: HTTPURLResponse) async throws {
        logger.info("Handling server response, status code: \(response.statusCode)")

        switch response.statusCode {
            case 200...299:
                logger.info("Form submission successful")
                if config.shouldClearForm {
                    logger.info("Clearing form after successful submission (delay: \(self.config.clearFormDelay, privacy: .public)s)")
                    try? await Task.sleep(for: .seconds(config.clearFormDelay))
                    userInput = .default
                }
                progressState = .completed

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
                logger.error("Form submission failed: unexpected status code \(response.statusCode, privacy: .public)")
                throw FormResponse.unexpectedError
        }
    }
}
