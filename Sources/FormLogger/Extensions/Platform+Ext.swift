//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import PlatformChecker

/// Represents supported Apple operating system types.
internal enum OSType: String {

    /// Apple’s mobile operating system for iPhone and iPad.
    case iOS

    /// Mac Catalyst, which allows iOS apps to run on macOS.
    case macCatalyst

    /// Apple’s desktop operating system.
    case macOS

    /// Apple’s operating system for Apple TV.
    case tvOS

    /// Apple’s operating system for Apple Watch.
    case watchOS

    /// Apple’s operating system for Vision Pro.
    case visionOS

    /// An unknown or unsupported operating system.
    case unknown
}

extension Platform {

    /// The current operating system type the app is running on.
    ///
    /// Evaluates a series of flags to determine the current OS and returns the corresponding
    /// `OSType`. Falls back to `.unknown` if no match is found.
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
