//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import Observation
@_exported import SimpleLogger

/// The resource bundle associated with this module.
///
/// Use this bundle to load assets such as localized strings, images, or other resources that are
/// packaged with the module.
public let module: Bundle = .module

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

    // MARK: - UI Form Attributes

    /// The primary title displayed at the top of the form.
    public var title: String = ""

    /// A descriptive message or body text associated with the form.
    public var message: String = ""

    /// The name of the contact submitting the form.
    public var contactName: String = ""

    /// The email address of the contact submitting the form.
    public var contactEmail: String = ""

    // MARK: - UI Form Toggle

    /// The type of form being submitted.
    ///
    /// This value typically controls conditional UI behaviour and downstream handling logic.
    public var kind: Kind = .bug

    /// A Boolean value indicating whether the user consents to being contacted.
    public var allowContact: Bool = true

    /// A Boolean value indicating whether diagnostic logs should be collected and attached to the
    /// submission.
    public var shouldCollectLogs: Bool = true

    // MARK: - Form Validation

    /// Validation errors keyed by form field.
    ///
    /// This dictionary is populated during validation and is read-only to external consumers to
    /// preserve consistency of validation state.
    public private(set) var fieldErrors: [Field : String] = [:]

    // MARK: - Progress State

    /// The current progress state of the form submission lifecycle.
    ///
    /// This value reflects whether the form is idle, validating, submitting, or has completed.
    public private(set) var progressState: ProgressState = .idle

    /// The configuration used to customise form behaviour and logging.
    ///
    /// This property is excluded from observation because it does not directly affect UI
    /// rendering.
    @ObservationIgnored
    private let config: FormConfiguration

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
    /// - All fields are valid, and
    /// - No submission or validation process is currently in progress.
    public var canSubmit: Bool {
        isFormValid && isProcessing == false
    }

    /// A Boolean value indicating whether the form passes validation.
    ///
    /// The form is considered valid when there are no validation errors recorded for any field.
    public var isFormValid: Bool {
        fieldErrors.isEmpty
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
    /// This method clears any existing errors, validates required fields, and conditionally
    /// validates contact information based on user consent.
    ///
    /// - Returns: `true` if all fields pass validation; otherwise, `false`.
    private func validateFormFields() -> Bool {
        clearAllErrors()

        validateTitle()
        validateMessage()

        if allowContact {
            validateContactName()
            validateContactEmail()
        }

        let isValid = fieldErrors.isEmpty
        if isValid {
            logger.info("Form validation passed")
        } else {
            logger.info("Form validation failed with \(self.fieldErrors.count) error(s)")
        }

        return fieldErrors.isEmpty
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
                    localized: "Message must be under \(config.characterLimit) characters."
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

// MARK: - Kind

extension FormManager {

    /// Represents the type of form being submitted.
    ///
    /// `Kind` defines the semantic intent of the submission and is used to drive UI presentation,
    /// labelling, and backend routing behaviour.
    ///
    /// Each case provides user-facing metadata such as a localized label and an associated SF
    /// Symbols system image.
    public enum Kind: String, CaseIterable, Identifiable, CustomStringConvertible {

        /// A submission intended to report a software defect or issue.
        case bug

        /// A submission intended to request new functionality or enhancements.
        case feature

        /// A general-purpose submission for comments or feedback.
        case feedback

        /// A stable identifier for the form kind.
        ///
        /// This value is derived from the kind's string description and is suitable for use in
        /// SwiftUI lists.
        public var id: String { description }

        /// A string representation of the form kind.
        ///
        /// The description includes the enum type name and raw value to provide clarity when
        /// logging or debugging.
        public var description: String {
            "\(Self.self).\(rawValue)"
        }

        /// A localized, user-facing label describing the form kind.
        ///
        /// This value is typically displayed in the UI when selecting or presenting the type of
        /// submission.
        public var label: String {
            switch self {
                case .bug:
                    String(localized: "Report a bug")
                case .feature:
                    String(localized: "Request a feature")
                case .feedback:
                    String(localized: "Send feedback")
            }
        }

        /// The SF Symbols system image name associated with the form kind.
        ///
        /// This value can be used directly with `Image(systemName:)` to visually distinguish
        /// submission types.
        public var systemImage: String {
            switch self {
                case .bug:
                    "ladybug"
                case .feature:
                    "party.popper"
                case .feedback:
                    "envelope"
            }
        }
    }
}

// MARK: - ProgressState

extension FormManager {

    /// Represents the current progress state of the form submission lifecycle.
    ///
    /// `ProgressState` models each discrete phase of submission, from idle through completion,
    /// and provides UI-friendly metadata such as display messages and progress values.
    public enum ProgressState: Equatable {

        /// The form is idle and no operation is currently in progress.
        case idle

        /// Diagnostic logs are being exported prior to submission.
        case exportingLogs

        /// The form payload is being submitted to the backend service.
        case submitting

        /// The server response is being processed after submission.
        case processingResponse

        /// The form is waiting to be cleared, with a countdown timer.
        ///
        /// - Parameter timeRemaining: The number of seconds remaining before the form is cleared.
        case clearingForm(timeRemaining: Int)

        /// The submission process has completed successfully.
        case completed

        /// A localized, user-facing message describing the current state.
        ///
        /// This value is typically displayed in the UI to inform the user of the current
        /// submission phase.
        public var displayMessage: String {
            switch self {
                case .idle:
                    return ""
                case .exportingLogs:
                    return String(localized: "Exporting logs…")
                case .submitting:
                    return String(localized: "Submitting…")
                case .processingResponse:
                    return String(localized: "Processing response…")
                case .clearingForm(let timeRemaining):
                    return String(localized: "Form will clear in \(timeRemaining)s…")
                case .completed:
                    return String(localized: "Submitted")
            }
        }

        /// A normalised progress value representing the current state.
        ///
        /// This value ranges from `0.0` to `1.0` and can be used to drive progress indicators
        /// in the UI.
        public var progress: Double {
            switch self {
                case .idle:
                    return 0.0
                case .exportingLogs:
                    return 0.2
                case .submitting:
                    return 0.6
                case .processingResponse:
                    return 0.8
                case .clearingForm:
                    return 0.9
                case .completed:
                    return 1.0
            }
        }
    }
}

// MARK: - Field

extension FormManager {

    /// Represents an individual field within the form.
    ///
    /// `Field` is used to identify form inputs for validation, error reporting, and UI labelling
    /// purposes.
    public enum Field: String {

        /// The form title field.
        case title

        /// The main message or body field.
        case message

        /// The contact name field.
        case contactName

        /// The contact email address field.
        case contactEmail

        /// A localized, user-facing label for the field.
        ///
        /// This value is typically displayed alongside the corresponding input control in the UI.
        internal var label: String {
            switch self {
                case .title:
                    String(localized: "Title")
                case .message:
                    String(localized: "Message")
                case .contactName:
                    String(localized: "Contact name")
                case .contactEmail:
                    String(localized: "Contact email")
            }
        }

        /// The default localized validation error message for the field.
        ///
        /// This message is used when validation fails and no custom error message is provided.
        internal var errorMessage: String {
            switch self {
                case .title:
                    String(localized: "Please provide a title.")
                case .message:
                    String(localized: "Please provide a message.")
                case .contactName:
                    String(localized: "Please provide your name.")
                case .contactEmail:
                    String(localized: "Please provide a valid email address.")
            }
        }
    }
}

// MARK: - FormResponse

extension FormManager {

    /// Represents errors that can occur during form submission.
    ///
    /// `FormResponse` maps network and server-side failures to user-facing, localised error
    /// titles and descriptions that are suitable for display in the UI.
    public enum FormResponse: Error, LocalizedError {

        /// The request was rejected due to invalid input or parameters.
        case badRequest

        /// The request failed due to missing or invalid authorisation.
        case unauthorized

        /// The server encountered an internal error.
        case serverError

        /// The server returned an unexpected HTTP status code.
        ///
        /// - Parameter Int: The unrecognised status code returned by the server.
        case unexpectedStatus(Int)

        /// The request failed due to a network-related error.
        ///
        /// - Parameter URLError: The underlying network error.
        case networkError(URLError)

        /// A short, localised title describing the error.
        ///
        /// This value is typically displayed as a headline or alert title to summarise the
        /// failure.
        public var errorTitle: String {
            switch self {
                case .badRequest:
                    return String(
                        localized: "Invalid Request",
                        comment: "Error title shown when the app cannot process the user's request due to invalid input or parameters."
                    )

                case .unauthorized:
                    return String(
                        localized: "Access Denied",
                        comment: "Error title shown when the user is not authorised to perform the requested action or access the resource."
                    )

                case .serverError:
                    return String(
                        localized: "Server Error",
                        comment: "Error title shown when the server returns an unexpected or invalid response."
                    )

                case .unexpectedStatus:
                    return String(
                        localized: "Unexpected Response",
                        comment: "Error title shown when the server returns an unrecognised status code."
                    )

                case .networkError:
                    return String(
                        localized: "Network Error",
                        comment: "Error title shown when there is no internet connection or the network request cannot be completed."
                    )
            }
        }

        /// A detailed, localised description of the error.
        ///
        /// This value provides additional context and guidance to help the user understand the
        /// failure and possible next steps.
        public var errorDescription: String? {
            switch self {
                case .badRequest:
                    return String(
                        localized: "The request was invalid. Please check the form and try again.",
                        comment: "Detailed error message shown when the user's request cannot be processed due to invalid input or parameters."
                    )

                case .unauthorized:
                    return String(
                        localized: "You're not authorised to perform this action. Please log in and try again.",
                        comment: "Detailed error message shown when the user attempts an action that requires authentication or higher privileges."
                    )

                case .serverError:
                    return String(
                        localized: "Something went wrong on our end. Please try again later.",
                        comment: "Detailed error message shown when the server encounters an internal problem or returns an unexpected response."
                    )

                case .unexpectedStatus(let statusCode):
                    return String(
                        localized: "The server returned an unexpected response (code \(statusCode)). Please try again later.",
                        comment: "Detailed error message shown when the server returns an unrecognised HTTP status code."
                    )

                case .networkError(let error):
                    let baseMessage = error.code.friendlyDescription
                    let additionalInfo = String(
                        localized: "If this keeps happening, please contact support.",
                        comment: "Additional suggestion shown after a network error, encouraging the user to reach out for support."
                    )
                    return "\(baseMessage)\n\n\(additionalInfo)"
            }
        }
    }
}
