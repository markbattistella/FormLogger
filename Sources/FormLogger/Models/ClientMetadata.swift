//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import PlatformChecker

/// A structure representing metadata about the client app and operating system.
///
/// Useful for logging, diagnostics, analytics, or when sending app context to a backend service.
internal struct ClientMetadata: Encodable {

    /// The internal name of the app, taken from `CFBundleName`.
    internal let appName: String = Bundle.main.appName

    /// The user-facing display name of the app, taken from `CFBundleDisplayName`.
    internal let appDisplayName: String = Bundle.main.appDisplayName

    /// The version number of the app (e.g., "1.2.3"), from `CFBundleShortVersionString`.
    internal let appVersion: String = Bundle.main.appVersion

    /// The build number of the app, from `CFBundleVersion`.
    internal let buildNumber: String = Bundle.main.buildNumber

    /// The app’s bundle identifier (e.g., "com.example.MyApp").
    internal let bundleId: String = Bundle.main.bundleId

    /// The current operating system as a string (e.g., "iOS", "macOS").
    internal let currentOS: String = Platform.currentOS.rawValue
}
