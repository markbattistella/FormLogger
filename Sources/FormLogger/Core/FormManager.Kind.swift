//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

extension FormManager {

    /// Represents the type of form being submitted.
    ///
    /// `Kind` defines the semantic intent of the submission and is used to drive UI presentation,
    /// labelling, and backend routing behaviour.
    ///
    /// Each case provides user-facing metadata such as a localized label and an associated SF
    /// Symbols system image.
    public enum Kind: String, CaseIterable, Identifiable, CustomStringConvertible, CustomDebugStringConvertible, Codable {

        /// A submission intended to report a software defect or issue.
        case bug

        /// A submission intended to request new functionality or enhancements.
        case feature

        /// A general-purpose submission for comments or feedback.
        case feedback

        /// A stable identifier for the form kind.
        ///
        /// This value is derived from the raw value and is suitable for use in SwiftUI lists.
        public var id: String { rawValue }

        /// A human-readable string representation of the form kind.
        public var description: String { rawValue }

        /// A debug string representation including the full type name.
        public var debugDescription: String { "\(Self.self).\(rawValue)" }

        /// A localized, user-facing label describing the form kind.
        ///
        /// This value is typically displayed in the UI when selecting or presenting the type of
        /// submission.
        public var label: String {
            switch self {
                case .bug:
                    String(localized: "Report a bug", bundle: .module)
                case .feature:
                    String(localized: "Request a feature", bundle: .module)
                case .feedback:
                    String(localized: "Send feedback", bundle: .module)
            }
        }

        /// The SF Symbols system image name associated with the form kind.
        ///
        /// This value can be used directly with `Image(systemName:)` to visually distinguish
        /// submission types.
        public var systemImage: String {
            switch self {
                case .bug:
                    "ladybug"
                case .feature:
                    "party.popper"
                case .feedback:
                    "envelope"
            }
        }
    }
}
