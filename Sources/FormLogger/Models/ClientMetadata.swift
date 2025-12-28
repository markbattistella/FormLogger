//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation
import PlatformChecker

/// Metadata describing the client application and runtime environment.
///
/// This type aggregates identifying information about the app and the operating system it is
/// running on. It is intended to be encoded and sent with network requests for diagnostics,
/// analytics, or backend processing.
internal struct ClientMetadata: Encodable {

    /// The app's internal bundle name.
    internal let appName: String

    /// The user-facing display name of the app.
    internal let appDisplayName: String

    /// The app's marketing version.
    internal let appVersion: String

    /// The app's build number.
    internal let buildNumber: String

    /// The app's bundle identifier.
    internal let bundleId: String

    /// The current operating system the app is running on.
    ///
    /// This value is derived from `Platform.currentOS`.
    internal let currentOS: String

    /// The operating system version string.
    internal let osVersion: String

    /// Creates a new `ClientMetadata` instance populated with values from the current app bundle
    /// and runtime environment.
    internal init() {
        self.appName = Bundle.main.appName
        self.appDisplayName = Bundle.main.appDisplayName
        self.appVersion = Bundle.main.appVersion
        self.buildNumber = Bundle.main.buildNumber
        self.bundleId = Bundle.main.bundleId
        self.currentOS = Platform.currentOS.rawValue
        self.osVersion = ProcessInfo.processInfo.operatingSystemVersionString
    }
}
