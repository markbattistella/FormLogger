//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import zlib

/// Represents an error that can occur during gzip compression.
internal struct GzipError: Error, Sendable {

    /// The specific kind of gzip error encountered.
    internal enum Kind: Equatable, Sendable {

        /// A stream error occurred (e.g. inconsistent stream state).
        case stream

        /// A data error occurred (e.g. corrupt input).
        case data

        /// A memory allocation failure occurred.
        case memory

        /// A buffer error occurred (e.g. output buffer too small).
        case buffer

        /// A version mismatch between the linked zlib and the compiled headers.
        case version

        /// An unknown error occurred, with the provided zlib error code.
        case unknown(code: Int)

        /// Creates a `Kind` from a zlib error code.
        ///
        /// - Parameter code: A zlib error code returned from a compression function.
        init(code: Int32) {
            switch code {
                case Z_STREAM_ERROR:
                    self = .stream
                case Z_DATA_ERROR:
                    self = .data
                case Z_MEM_ERROR:
                    self = .memory
                case Z_BUF_ERROR:
                    self = .buffer
                case Z_VERSION_ERROR:
                    self = .version
                default:
                    self = .unknown(code: Int(code))
            }
        }
    }

    /// The specific type of error that occurred.
    internal let kind: Kind

    /// A human-readable description of the error.
    internal let message: String

    /// Creates a new `GzipError` from a zlib error code and optional message pointer.
    ///
    /// - Parameters:
    ///   - code: The zlib error code.
    ///   - msg: An optional C string containing a message from zlib.
    internal init(code: Int32, msg: UnsafePointer<CChar>?) {
        self.message = msg.flatMap(String.init(validatingCString:)) ?? "Unknown gzip error"
        self.kind = Kind(code: code)
    }

    /// A localized, human-readable description of the error.
    internal var localizedDescription: String {
        return self.message
    }
}
