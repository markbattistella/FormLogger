//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import Observation
@_exported import SimpleLogger

/// Manages the state, validation, and submission lifecycle of a user-facing form.
///
/// `FormManager` is responsible for:
/// - Holding user-entered form data
/// - Managing UI-related toggle state
/// - Tracking validation errors
/// - Coordinating logging and progress state during submission
///
/// The class is isolated to the main actor to ensure thread-safe interaction with UI-bound state
/// and is observable so that changes automatically propagate to SwiftUI views.
@MainActor
@Observable
public final class FormManager {
    
    /// The primary title displayed at the top of the form.
    public var title: String = ""
    
    /// A descriptive message or body text associated with the form.
    public var message: String = ""
    
    /// The name of the contact submitting the form.
    public var contactName: String = ""
    
    /// The email address of the contact submitting the form.
    public var contactEmail: String = ""

    /// The type of form being submitted.
    ///
    /// This value typically controls conditional UI behaviour and downstream handling logic.
    public var kind: Kind = .bug
    
    /// A Boolean value indicating whether the user consents to being contacted.
    public var allowContact: Bool = true
    
    /// A Boolean value indicating whether diagnostic logs should be collected and attached to the
    /// submission.
    public var shouldCollectLogs: Bool = true

    /// Validation errors keyed by form field.
    ///
    /// This dictionary is populated during validation and is read-only to external consumers to
    /// preserve consistency of validation state.
    public private(set) var fieldErrors: [Field : String] = [:]

    /// The current progress state of the form submission lifecycle.
    ///
    /// This value reflects whether the form is idle, validating, submitting, or has completed.
    public private(set) var progressState: ProgressState = .idle

    /// The current validation state of the form.
    ///
    /// This value tracks the lifecycle of form validation independently from submission progress
    /// and is used to distinguish between unvalidated, validating, valid, and invalid states.
    @ObservationIgnored
    private var validationState: ValidationState = .unvalidated

    /// The configuration used to customise form behaviour and logging.
    ///
    /// This property is excluded from observation because it does not directly affect UI
    /// rendering.
    @ObservationIgnored
    private var config: any FormConfiguration
    
    /// Manages log collection and lifecycle during form submission.
    ///
    /// This property is excluded from observation as it represents internal infrastructure
    /// rather than UI state.
    @ObservationIgnored
    private let loggerManager: LoggerManager
    
    /// Logger used to record form submission–related events.
    ///
    /// This logger is scoped to the form submission category and is excluded from observation.
    @ObservationIgnored
    private let logger = SimpleLogger(category: .formSubmission)
    
    /// Creates a new form manager with the specified configuration.
    ///
    /// The configuration is applied immediately and is responsible for customising the logger
    /// manager before it is stored.
    ///
    /// - Parameter config: A configuration object that defines form behaviour and logging setup.
    public init(config: FormConfiguration) {
        self.config = config
        
        let loggerManager = LoggerManager()
        config.configureLogger(loggerManager)
        self.loggerManager = loggerManager
    }
}

// MARK: - Processing State

extension FormManager {
    
    /// A Boolean value indicating whether the form is currently processing.
    ///
    /// This value is `true` whenever the form is in a non-idle progress state, such as validating
    /// or submitting.
    public var isProcessing: Bool {
        progressState != .idle
    }
    
    /// A Boolean value indicating whether the form can be submitted.
    ///
    /// The form can be submitted only when:
    /// - The form has been validated successfully, and
    /// - No validation or submission process is currently in progress.
    public var canSubmit: Bool {
        validationState == .valid && !isProcessing
    }
    
    /// A Boolean value indicating whether the form is currently in a valid state.
    ///
    /// This value is `true` only after a successful validation pass has completed. A newly
    /// initialised form, or a form that has not yet been validated, is not considered valid.
    public var isFormValid: Bool {
        validationState == .valid
    }
    
    /// The maximum allowed number of characters for the message field.
    ///
    /// This value is derived from the form configuration and is typically used by the UI to
    /// enforce or display character limits.
    public var messageCharacterLimit: Int {
        config.characterLimit
    }
}

// MARK: - Validation

extension FormManager {
    
    /// Removes all validation errors from the form.
    ///
    /// This method resets the validation state by clearing all field-specific error messages and
    /// records the action in the form submission log.
    public func clearAllErrors() {
        fieldErrors.removeAll()
        logger.debug("Cleared all field errors")
    }
    
    /// Removes the validation error associated with a specific field.
    ///
    /// - Parameter field: The form field whose validation error should be cleared.
    public func clearError(for field: Field) {
        fieldErrors[field] = nil
        logger.debug("Cleared error for field: \(field.label, privacy: .public)")
    }
    
    /// Validates all relevant form fields and updates the validation state.
    ///
    /// This method performs a full validation pass over the form by:
    /// - Clearing any existing validation errors
    /// - Validating required title and message fields
    /// - Conditionally validating contact details when contact is allowed
    ///
    /// The validation lifecycle is reflected in `validationState`, transitioning through
    /// `.validating` and then to either `.valid` or `.invalid`.
    ///
    /// - Returns: `true` if all fields pass validation; otherwise, `false`.
    private func validateFormFields() -> Bool {
        validationState = .validating
        clearAllErrors()
        
        validateTitle()
        validateMessage()
        
        if allowContact {
            validateContactName()
            validateContactEmail()
        }
        
        let isValid = fieldErrors.isEmpty
        validationState = isValid ? .valid : .invalid
        if isValid {
            logger.info("Form validation passed")
        } else {
            logger.info("Form validation failed with \(self.fieldErrors.count) error(s)")
        }
        
        return isValid
    }
    
    /// Validates the form title field.
    ///
    /// The title is considered invalid if it contains only whitespace or newline characters.
    private func validateTitle() {
        if title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            setError(.title)
        }
    }
    
    /// Validates the message field.
    ///
    /// The message must be non-empty after trimming whitespace and must not exceed the configured
    /// character limit.
    private func validateMessage() {
        let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            setError(.message)
        } else if trimmed.count > config.characterLimit {
            setError(
                .message,
                message: String(
                    localized: "Message must be under \(config.characterLimit) characters.",
                    bundle: .module
                )
            )
        }
    }
    
    /// Validates the contact name field.
    ///
    /// The contact name is required when contact is allowed and is invalid if it contains only
    /// whitespace or newline characters.
    private func validateContactName() {
        if contactName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            setError(.contactName)
        }
    }
    
    /// Validates the contact email field.
    ///
    /// The email address must be non-empty and conform to a basic email address format when
    /// contact is allowed.
    private func validateContactEmail() {
        let email = contactEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if email.isEmpty || !isValidEmail(email) {
            setError(.contactEmail)
        }
    }
    
    /// Records a validation error for a specific field.
    ///
    /// If a custom message is provided, it is used; otherwise, the field's default error message
    /// is applied.
    ///
    /// - Parameters:
    ///   - field: The field that failed validation.
    ///   - message: An optional custom error message to associate with the field.
    private func setError(_ field: Field, message: String? = nil) {
        if let message {
            fieldErrors[field] = message
        } else {
            fieldErrors[field] = field.errorMessage
        }
        logger.debug("Validation failed for field: \(field.label, privacy: .public)")
    }
    
    /// Evaluates whether an email address string is valid.
    ///
    /// This method performs a case-insensitive regular expression match against a basic email
    /// format.
    ///
    /// - Parameter email: The email address string to validate.
    /// - Returns: `true` if the email matches the expected format; otherwise, `false`.
    private func isValidEmail(_ email: String) -> Bool {
        let regex = "^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,12}$"
        return NSPredicate(format: "SELF MATCHES[c] %@", regex)
            .evaluate(with: email)
    }
}

// MARK: - Log Export

extension FormManager {
    
    /// Exports collected logs to a temporary file on disk.
    ///
    /// This method fetches the latest logs, exports them in a compressed gzip log format, and
    /// writes the resulting data to the system's temporary directory.
    ///
    /// The filename includes an ISO 8601 timestamp to ensure uniqueness. The progress state is
    /// updated while the export is in progress.
    ///
    /// - Returns: The file URL of the exported log archive.
    /// - Throws: An error if log export fails or the file cannot be written.
    private func exportLogsToTemporaryFile() async throws -> URL {
        logger.debug("Starting log export to temporary file")
        
        await loggerManager.fetch()
        let result = await loggerManager.export(format: .gzip(.log))
        
        switch result {
            case .success(let data):
                do {
                    progressState = .exportingLogs
                    let filename = "logs_\(Date.now.formatted(.iso8601))"
                        .replacingOccurrences(of: ":", with: ".")
                    
                    let url = FileManager.default.temporaryDirectory
                        .appendingPathComponent(filename)
                        .appendingPathExtension(Export.Format.gzip(.log).filenameSuffix)
                    
                    try data.write(to: url, options: .atomic)
                    logger.info("Log export successful: \(url.lastPathComponent, privacy: .public), size: \(data.count) bytes")
                    return url
                } catch {
                    logger.error("Failed to write log file to temporary directory: \(error.localizedDescription, privacy: .public)")
                    throw error
                }
                
            case .failure(let error):
                progressState = .idle
                logger.error("Log export failed: \(error.localizedDescription, privacy: .public)")
                throw error
        }
    }
}

// MARK: - Form Submission

extension FormManager {
    
    /// Submits the form payload to the configured backend service.
    ///
    /// This method performs the complete submission lifecycle:
    /// - Validates all form fields
    /// - Builds the submission payload
    /// - Optionally exports and attaches diagnostic logs
    /// - Sends a multipart request to the API
    /// - Handles success, failure, and cleanup states
    ///
    /// Progress state transitions are updated throughout the process to reflect validation,
    /// submission, and response handling.
    ///
    /// - Throws: A `FormResponse` for known submission or network errors, or any unexpected error
    /// encountered during the process.
    public func submit() async throws {
        let startTime = Date.now
        
        logger.info("Form submission started - type: \(self.kind.rawValue, privacy: .public)")
        
        guard validateFormFields() else {
            logger.notice("Form submission aborted due to validation errors")
            progressState = .idle
            return
        }
        
        let payload = FormPayload(
            title: title,
            message: message,
            contactName: allowContact ? contactName : nil,
            contactEmail: allowContact ? contactEmail : nil,
            repository: config.repository.getRepository(for: kind),
            label: kind.rawValue,
            customMetadata: config.customMetadata
        )
        logger.debug("Payload created - contact info included: \(self.allowContact, privacy: .public)")
        
        var logFileURL: URL? = nil
        
        if shouldCollectLogs {
            do {
                logFileURL = try await exportLogsToTemporaryFile()
            } catch {
                logger.warning("Log export failed, continuing without logs: \(error.localizedDescription, privacy: .public)")
                logFileURL = nil
            }
        } else {
            logger.debug("Log collection disabled, skipping export")
        }
        
        defer {
            if let logFileURL {
                try? FileManager.default.removeItem(at: logFileURL)
                logger.debug("Temporary log file cleaned up")
            }
            
            let totalDuration = Date.now.timeIntervalSince(startTime)
            logger.info("Form submission completed in \(totalDuration.formatted(.number.precision(.fractionLength(2))))s (including UI delays)")
            
            progressState = .idle
        }
        
        if config.isDryRun {
            debugPrintSubmission(payload: payload, logFileURL: logFileURL)
            progressState = .completed
            return
        }
        
        do {
            progressState = .submitting
            logger.debug("Sending multipart request to API")
            let (_, response) = try await MultipartRequest.send(
                to: config.apiURL,
                payload: payload,
                logFileURL: logFileURL
            )
            
            try validateHTTPResponse(response)
            
            let submissionDuration = Date.now.timeIntervalSince(startTime)
            logger.info("Form submission sent successfully in \(submissionDuration.formatted(.number.precision(.fractionLength(2))))s")
            
            progressState = .processingResponse
            await handleSuccessfulSubmissionUX()
            
        } catch let error as FormResponse {
            logger.error("Form submission failed: \(error.errorTitle, privacy: .public)")
            throw error
            
        } catch let error as URLError {
            logger.error("Network error during submission: \(error.localizedDescription, privacy: .public)")
            let formError = FormResponse.networkError(error)
            throw formError
            
        } catch {
            logger.error("Unexpected error during submission: \(error.localizedDescription, privacy: .public)")
            throw error
        }
    }
    
    #if DEBUG
    /// Prints the form submission payload and attachments to the console.
    ///
    /// This method is used only in debug builds to inspect the data that would be sent during a
    /// form submission when running in dry-run mode.
    ///
    /// - Parameters:
    ///   - payload: The form payload that would be submitted.
    ///   - logFileURL: The URL of the exported log file, if one was generated.
    private func debugPrintSubmission(
        payload: FormPayload,
        logFileURL: URL?
    ) {
        print("=== FORM SUBMISSION (DRY RUN) ===")
        print("Kind:", kind.rawValue)
        print("Title:", payload.title)
        print("Message:", payload.message)
        
        if let name = payload.contactName {
            print("Contact Name:", name)
        }
        
        if let email = payload.contactEmail {
            print("Contact Email:", email)
        }
        
        print("Repository:", config.repository.getRepository(for: kind))
        print("Custom Metadata:", config.customMetadata ?? [:])
        
        if let logFileURL {
            print("Logs attached at:", logFileURL.path)
        } else {
            print("No logs attached")
        }
        
        print("================================")
    }
    #endif
}

// MARK: - Form Clearing

extension FormManager {
    
    /// Resets all user-editable form fields and validation errors.
    ///
    /// This method clears the form's textual content, removes any contact information, and resets
    /// all validation errors to their initial state.
    ///
    /// It is typically called after a successful submission or when the form needs to be returned
    /// to a clean state.
    private func clearForm() {
        title = ""
        message = ""
        contactName = ""
        contactEmail = ""
        fieldErrors.removeAll()
        logger.debug("Form cleared - all fields and errors reset")
    }
}

// MARK: - Response Handling

extension FormManager {
    
    /// Validates an HTTP response returned from the form submission request.
    ///
    /// This method maps known HTTP status codes to domain-specific `FormResponse` errors and
    /// treats any 2xx status code as success.
    ///
    /// - Parameter response: The HTTP response received from the server.
    /// - Throws: A `FormResponse` corresponding to the response status code if the request was
    /// not successful.
    private func validateHTTPResponse(_ response: HTTPURLResponse) throws {
        switch response.statusCode {
            case 200...299:
                return
                
            case 400:
                throw FormResponse.badRequest
                
            case 401:
                throw FormResponse.unauthorized
                
            case 500:
                throw FormResponse.serverError
                
            default:
                throw FormResponse.unexpectedStatus(response.statusCode)
        }
    }
    
    /// Handles user experience updates following a successful form submission.
    ///
    /// This method:
    /// - Logs the successful submission
    /// - Optionally clears the form after a configurable delay
    /// - Updates the progress state to reflect countdown and completion
    ///
    /// The delay allows the UI to present a confirmation state before resetting the form contents.
    private func handleSuccessfulSubmissionUX() async {
        logger.info("Form submission successful")
        
        if config.shouldClearForm {
            let totalSeconds = Int(config.clearFormDelay.components.seconds)
            
            for secondsRemaining in (1...totalSeconds).reversed() {
                progressState = .clearingForm(timeRemaining: secondsRemaining)
                try? await Task.sleep(for: .seconds(1))
            }
            
            clearForm()
        }
        
        progressState = .completed
        try? await Task.sleep(for: .seconds(1))
    }
}

// MARK: - Metadata Injection

extension FormManager {
    public func mergeMetadata(_ metadata: [String: String]) {
        if config.customMetadata != nil {
            config.customMetadata?.merge(metadata) { _, dynamic in dynamic }
        } else {
            config.customMetadata = metadata
        }
        logger.debug("Merged \(metadata.count) metadata entries")
    }
}
