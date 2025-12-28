//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import PlatformChecker

extension Platform {

    /// Supported operating system types.
    ///
    /// These values represent the platforms the app may be running on and are used to normalise
    /// platform checks into a single, strongly typed model.
    internal enum OSType: String {

        /// Apple iPhone and iPad operating system.
        case iOS

        /// iOS app running on macOS via Mac Catalyst.
        case macCatalyst

        /// Native macOS application.
        case macOS

        /// Apple TV operating system.
        case tvOS

        /// Apple Watch operating system.
        case watchOS

        /// Apple Vision Pro operating system.
        case visionOS

        /// An unknown or unsupported operating system.
        case unknown
    }

    /// The operating system the app is currently running on.
    ///
    /// This property evaluates platform-specific checks in a defined order and returns the
    /// corresponding `OSType`. If no known platform is detected, `.unknown` is returned.
    internal static var currentOS: OSType {
        if isMacCatalyst {
            return .macCatalyst
        } else if isiOS {
            return .iOS
        } else if isMacOS {
            return .macOS
        } else if isTVOS {
            return .tvOS
        } else if isWatchOS {
            return .watchOS
        } else if isVisionOS {
            return .visionOS
        } else {
            return .unknown
        }
    }
}
