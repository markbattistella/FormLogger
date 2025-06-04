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
}




extension Data {

    internal func gzipped(
        level: CompressionLevel = .defaultCompression,
        wBits: Int32 = Gzip.maxWindowBits + 16
    ) throws(GzipError) -> Data {

        guard !self.isEmpty else {
            return Data()
        }

        var stream = z_stream()
        var status: Int32

        status = deflateInit2_(
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

        var data = Data(capacity: DataSize.chunk)
        repeat {
            if Int(stream.total_out) >= data.count {
                data.count += DataSize.chunk
            }

            let inputCount = self.count
            let outputCount = data.count

            self.withUnsafeBytes { (inputPointer: UnsafeRawBufferPointer) in
                stream.next_in = UnsafeMutablePointer<Bytef>(mutating: inputPointer.bindMemory(to: Bytef.self).baseAddress!)
                    .advanced(by: Int(stream.total_in))
                stream.avail_in = uInt(inputCount) - uInt(stream.total_in)

                data.withUnsafeMutableBytes { (outputPointer: UnsafeMutableRawBufferPointer) in
                    stream.next_out = outputPointer.bindMemory(to: Bytef.self).baseAddress!.advanced(by: Int(stream.total_out))
                    stream.avail_out = uInt(outputCount) - uInt(stream.total_out)
                    status = deflate(&stream, Z_FINISH)
                    stream.next_out = nil
                }

                stream.next_in = nil
            }

        } while stream.avail_out == 0 && status != Z_STREAM_END

        guard deflateEnd(&stream) == Z_OK, status == Z_STREAM_END else {
            throw GzipError(code: status, msg: stream.msg)
        }

        data.count = Int(stream.total_out)

        return data
    }
}

private enum DataSize {
    static let chunk = 1 << 14
    static let stream = MemoryLayout<z_stream>.size
}

internal enum Gzip {
    internal static let maxWindowBits = MAX_WBITS
}

internal struct CompressionLevel: RawRepresentable, Sendable {
    internal let rawValue: Int32

    internal static let noCompression = Self(Z_NO_COMPRESSION)
    internal static let bestSpeed = Self(Z_BEST_SPEED)
    internal static let bestCompression = Self(Z_BEST_COMPRESSION)
    internal static let defaultCompression = Self(Z_DEFAULT_COMPRESSION)

    internal init(rawValue: Int32) {
        self.rawValue = rawValue
    }

    internal init(_ rawValue: Int32) {
        self.rawValue = rawValue
    }
}

internal struct GzipError: Error, Sendable {
    internal enum Kind: Equatable, Sendable {
        case stream
        case data
        case memory
        case buffer
        case version
        case unknown(code: Int)
    }

    internal let kind: Kind
    internal let message: String
    internal init(code: Int32, msg: UnsafePointer<CChar>?) {
        self.message = msg.flatMap(String.init(validatingUTF8:)) ?? "Unknown gzip error"
        self.kind = Kind(code: code)
    }

    internal var localizedDescription: String {
        return self.message
    }
}

private extension GzipError.Kind {
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
