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
public struct ClientMetadata: Encodable {

    /// The internal name of the app, taken from `CFBundleName`.
    public let appName: String = Bundle.main.appName

    /// The user-facing display name of the app, taken from `CFBundleDisplayName`.
    public let appDisplayName: String = Bundle.main.appDisplayName

    /// The version number of the app (e.g., "1.2.3"), from `CFBundleShortVersionString`.
    public let appVersion: String = Bundle.main.appVersion

    /// The build number of the app, from `CFBundleVersion`.
    public let buildNumber: String = Bundle.main.buildNumber

    /// The app’s bundle identifier (e.g., "com.example.MyApp").
    public let bundleId: String = Bundle.main.bundleId

    /// The current operating system as a string (e.g., "iOS", "macOS").
    public let currentOS: String = Platform.currentOS.rawValue
}
