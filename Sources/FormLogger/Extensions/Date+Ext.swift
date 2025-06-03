//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

extension Date {

    /// A string representation of the date formatted in ISO 8601, safe for use in filenames.
    ///
    /// This replaces colons (`:`) with dots (`.`) to avoid issues with filesystems
    /// that disallow or treat colons specially in filenames.
    internal var filenameISO8601: String {
        formatted(.iso8601)
            .replacingOccurrences(of: ":", with: ".")
    }
}
