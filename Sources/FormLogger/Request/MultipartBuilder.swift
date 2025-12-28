//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

/// A utility for building multipart/form-data request bodies.
///
/// This type is responsible for serialising a `FormPayload` and optional log file into a
/// temporary file formatted as a multipart body suitable for HTTP uploads.
internal enum MultipartBuilder {

    /// Logger used for multipart body construction.
    private static let logger = SimpleLogger(category: .formSubmission)

    /// Builds a multipart/form-data body file on disk.
    ///
    /// This method creates a temporary file containing:
    /// - A JSON-encoded form payload
    /// - An optional log file attachment
    ///
    /// The resulting file can be streamed or uploaded without holding the entire multipart body
    /// in memory.
    ///
    /// - Parameters:
    ///   - boundary: The multipart boundary string used to separate parts.
    ///   - payload: The form payload to encode as JSON.
    ///   - logFileURL: An optional URL to a log file to include as an attachment.
    /// - Returns: A file URL pointing to the generated multipart body file.
    /// - Throws: A `CocoaError` if the file cannot be created, written to, or if encoding fails.
    internal static func buildMultipartBodyFile(
        boundary: String,
        payload: FormPayload,
        logFileURL: URL?
    ) throws -> URL {
        logger.debug("Building multipart body file with boundary: \(boundary, privacy: .public)")

        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("multipart_\(boundary)")
            .appendingPathExtension("body")

        guard FileManager.default.createFile(atPath: tempURL.path, contents: nil) else {
            logger.error("Failed to create temporary multipart file")
            throw CocoaError(.fileWriteUnknown)
        }

        let handle = try FileHandle(forWritingTo: tempURL)
        defer { try? handle.close() }

        /// Writes a UTF-8 encoded string to the multipart file.
        ///
        /// - Parameter string: The string to write.
        /// - Throws: A `CocoaError` if the string cannot be encoded or written.
        @inline(__always)
        func write(_ string: String) throws {
            guard let data = string.data(using: .utf8) else {
                logger.error("Failed to encode string data as UTF-8")
                throw CocoaError(.fileWriteInapplicableStringEncoding)
            }
            try handle.write(contentsOf: data)
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let jsonData = try encoder.encode(payload)
        logger.debug("Encoded JSON payload: \(jsonData.count) bytes")

        try write("--\(boundary)\r\n")
        try write("Content-Disposition: form-data; name=\"requestBody\"\r\n")
        try write("Content-Type: application/json; charset=utf-8\r\n\r\n")
        try handle.write(contentsOf: jsonData)
        try write("\r\n")

        if let logFileURL {
            logger.debug("Attaching log file: \(logFileURL.lastPathComponent, privacy: .public)")

            let logHandle = try FileHandle(forReadingFrom: logFileURL)
            defer { try? logHandle.close() }

            let mimeType = logFileURL.pathExtension.lowercased() == "gz"
            ? "application/gzip"
            : "application/octet-stream"

            try write("--\(boundary)\r\n")
            try write("Content-Disposition: form-data; name=\"logs\"; filename=\"\(logFileURL.lastPathComponent)\"\r\n")
            try write("Content-Type: \(mimeType)\r\n\r\n")

            var totalBytes = 0
            while let chunk = try logHandle.read(upToCount: 64 * 1024),
                  !chunk.isEmpty {
                try handle.write(contentsOf: chunk)
                totalBytes += chunk.count
            }

            logger.debug("Wrote log file: \(totalBytes) bytes")
            try write("\r\n")
        } else {
            logger.debug("No log file attached")
        }

        try write("--\(boundary)--\r\n")

        logger.info("Multipart body file created successfully at: \(tempURL.lastPathComponent, privacy: .public)")
        return tempURL
    }
}
