//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A utility for sending multipart/form-data HTTP requests.
///
/// This type coordinates multipart body construction and network upload for form submissions,
/// ensuring work is performed on the main actor where required.
@MainActor
internal enum MultipartRequest {

    /// Logger used for multipart request lifecycle events.
    private static let logger = SimpleLogger(category: .formSubmission)

    /// Sends a multipart/form-data POST request.
    ///
    /// This method:
    /// - Builds a multipart body file containing the form payload and an optional log file
    /// - Uploads the file using `URLSession`
    /// - Cleans up temporary resources after completion
    ///
    /// - Parameters:
    ///   - url: The endpoint to which the request is sent.
    ///   - payload: The form payload to include in the request body.
    ///   - logFileURL: An optional URL to a log file to attach.
    /// - Returns: A tuple containing the response data and the HTTP response.
    /// - Throws: A `URLError` or other error if request construction, upload, or response
    /// validation fails.
    internal static func send(
        to url: URL,
        payload: FormPayload,
        logFileURL: URL?
    ) async throws -> (Data, HTTPURLResponse) {

        logger.info("Preparing multipart request to: \(url.absoluteString, privacy: .public)")

        let boundary = UUID().uuidString

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        request.setValue(
            "multipart/form-data; boundary=\(boundary)",
            forHTTPHeaderField: "Content-Type"
        )

        request.setValue(
            "application/json",
            forHTTPHeaderField: "Accept"
        )

        let multipartFileURL = try MultipartBuilder.buildMultipartBodyFile(
            boundary: boundary,
            payload: payload,
            logFileURL: logFileURL
        )

        defer {
            try? FileManager.default.removeItem(at: multipartFileURL)
            logger.debug("Cleaned up temporary multipart file")
        }

        logger.debug("Uploading multipart request")
        let (data, response) = try await URLSession.shared.upload(
            for: request,
            fromFile: multipartFileURL
        )

        guard let httpResponse = response as? HTTPURLResponse else {
            logger.error("Invalid response type - expected HTTPURLResponse")
            throw URLError(.badServerResponse)
        }

        logger.info("Multipart request completed with status: \(httpResponse.statusCode)")
        return (data, httpResponse)
    }
}
