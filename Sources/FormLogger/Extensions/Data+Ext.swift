//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import zlib

extension Data {

    /// Appends a string to the data using the specified encoding.
    ///
    /// If the string cannot be encoded, the method does nothing.
    ///
    /// - Parameters:
    ///   - string: The string to append.
    ///   - encoding: The string encoding to use. Defaults to `.utf8`.
    internal mutating func append(_ string: String, encoding: String.Encoding = .utf8) {
        guard let data = string.data(using: encoding) else { return }
        append(data)
    }

    /// Returns a gzip-compressed version of the data.
    ///
    /// - Parameters:
    ///   - level: The compression level to apply. Defaults to `.defaultCompression`.
    ///   - wBits: The window bits value to configure zlib's behaviour. Defaults to
    ///   `MAX_WBITS + 16` to enable gzip headers.
    /// - Throws: A `GzipError` if compression fails.
    /// - Returns: A `Data` object containing the compressed bytes.
    internal func gzipped(
        level: CompressionLevel = .defaultCompression,
        wBits: Int32 = MAX_WBITS + 16
    ) throws(GzipError) -> Data {
        guard !self.isEmpty else { return Data() }

        var stream = z_stream()
        var status: Int32 = deflateInit2_(
            &stream,
            level.rawValue,
            Z_DEFLATED,
            wBits,
            MAX_MEM_LEVEL,
            Z_DEFAULT_STRATEGY,
            ZLIB_VERSION,
            Int32(DataSize.stream)
        )

        guard status == Z_OK else {
            throw GzipError(code: status, msg: stream.msg)
        }

        var compressedData = Data(capacity: DataSize.chunk)

        repeat {
            if Int(stream.total_out) >= compressedData.count {
                compressedData.count += DataSize.chunk
            }

            let inputSize = self.count
            let outputSize = compressedData.count

            self.withUnsafeBytes { inputPointer in
                guard let baseInput = inputPointer
                    .bindMemory(to: Bytef.self)
                    .baseAddress else { return }

                stream.next_in = UnsafeMutablePointer(mutating: baseInput.advanced(by: Int(stream.total_in)))
                stream.avail_in = uInt(inputSize) - uInt(stream.total_in)

                compressedData.withUnsafeMutableBytes { outputPointer in
                    guard let baseOutput = outputPointer
                        .bindMemory(to: Bytef.self)
                        .baseAddress else { return }

                    stream.next_out = baseOutput.advanced(by: Int(stream.total_out))
                    stream.avail_out = uInt(outputSize) - uInt(stream.total_out)

                    status = deflate(&stream, Z_FINISH)
                }
            }
        } while stream.avail_out == 0 && status != Z_STREAM_END

        guard deflateEnd(&stream) == Z_OK, status == Z_STREAM_END else {
            throw GzipError(code: status, msg: stream.msg)
        }

        compressedData.count = Int(stream.total_out)
        return compressedData
    }
}

/// Constants related to buffer sizing used during compression.
fileprivate enum DataSize {

    /// Size of each output chunk (16 KB).
    static let chunk = 1 << 14

    /// Size of the zlib stream structure.
    static let stream = MemoryLayout<z_stream>.size
}

/// A wrapper for zlib compression levels, providing type safety and convenience.
internal struct CompressionLevel: RawRepresentable, Sendable {

    /// The underlying raw zlib compression level value.
    internal let rawValue: Int32

    /// No compression (`Z_NO_COMPRESSION`).
    internal static let noCompression = Self(Z_NO_COMPRESSION)

    /// Fastest compression, lowest ratio (`Z_BEST_SPEED`).
    internal static let bestSpeed = Self(Z_BEST_SPEED)

    /// Slowest compression, best ratio (`Z_BEST_COMPRESSION`).
    internal static let bestCompression = Self(Z_BEST_COMPRESSION)

    /// Default compression level (`Z_DEFAULT_COMPRESSION`).
    internal static let defaultCompression = Self(Z_DEFAULT_COMPRESSION)

    /// Creates a `CompressionLevel` from a raw zlib value.
    ///
    /// - Parameter rawValue: A raw `Int32` compression level from zlib.
    internal init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    /// Convenience initialiser mirroring `init(rawValue:)`.
    ///
    /// - Parameter rawValue: A raw `Int32` compression level from zlib.
    internal init(_ rawValue: Int32) {
        self.rawValue = rawValue
    }
}
