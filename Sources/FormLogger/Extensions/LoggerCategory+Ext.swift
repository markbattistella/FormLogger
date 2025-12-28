//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import SimpleLogger

extension LoggerCategory {

    /// A logging category for form submission–related events.
    ///
    /// Use this category to group log messages associated with validating, submitting, and
    /// processing forms. This allows form submission logs to be easily filtered and analysed
    /// in logging tools.
    static let formSubmission = LoggerCategory("FormSubmission")
}
