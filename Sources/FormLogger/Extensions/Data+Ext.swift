//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import zlib

extension Data {

    /// Appends a string to the `Data` object using the specified string encoding.
    ///
    /// - Parameters:
    ///   - string: The string to append.
    ///   - encoding: The encoding used to convert the string to data. Defaults to `.utf8`.
    internal mutating func append(_ string: String, encoding: String.Encoding = .utf8) {
        guard let data = string.data(using: encoding) else { return }
        append(data)
    }

    /// Compresses the data using GZIP compression.
    ///
    /// - Returns: A new `Data` object containing the compressed data in GZIP format.
    /// - Throws: An `NSError` if compression fails to initialise or complete.
    ///
    /// This method uses the zlib library and applies GZIP-specific headers by setting the
    /// `windowBits` parameter to 31.
    internal func gzipped() throws -> Data {
        var stream = z_stream()
        stream.next_in = UnsafeMutablePointer<Bytef>(
            mutating: self.withUnsafeBytes { $0.bindMemory(to: Bytef.self).baseAddress }
        )
        stream.avail_in = uint(self.count)

        let chunkSize = 16_384
        var compressedData = Data()
        var output = [UInt8](repeating: 0, count: chunkSize)

        // Initialise the stream with GZIP settings (windowBits = 31)
        guard deflateInit2_(
            &stream,
            Z_DEFAULT_COMPRESSION,
            Z_DEFLATED,
            31,
            8,
            Z_DEFAULT_STRATEGY,
            ZLIB_VERSION,
            Int32(MemoryLayout<z_stream>.size)
        ) == Z_OK else {
            throw NSError(domain: "GZIP", code: -1, userInfo: nil)
        }

        // Perform compression
        repeat {
            stream.next_out = UnsafeMutablePointer<Bytef>(&output)
            stream.avail_out = uInt(output.count)

            deflate(&stream, Z_FINISH)
            compressedData.append(&output, count: output.count - Int(stream.avail_out))
        } while stream.avail_out == 0

        deflateEnd(&stream)
        return compressedData
    }
}
