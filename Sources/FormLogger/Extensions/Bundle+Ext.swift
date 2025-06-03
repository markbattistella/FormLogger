//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

extension Bundle {

    /// The name of the app as specified in the Info.plist under `CFBundleName`.
    internal var appName: String {
        object(forInfoDictionaryKey: "CFBundleName") as? String ?? ""
    }

    /// The build number of the app as specified in the Info.plist under `CFBundleVersion`.
    internal var buildNumber: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? ""
    }

    /// The version number of the app as specified in the Info.plist under `CFBundleShortVersionString`.
    internal var appVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }

    /// The bundle identifier of the app as specified in the Info.plist under `CFBundleIdentifier`.
    internal var bundleId: String {
        object(forInfoDictionaryKey: "CFBundleIdentifier") as? String ?? ""
    }

    /// The display name of the app as specified in the Info.plist under `CFBundleDisplayName`.
    ///
    /// Falls back to an empty string if not set.
    internal var appDisplayName: String {
        object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? ""
    }
}
