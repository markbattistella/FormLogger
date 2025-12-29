//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import Foundation

extension FormManager {
    
    /// Represents the validation lifecycle state of the form.
    ///
    /// This enum models whether the form has not yet been validated, is currently undergoing
    /// validation, or has completed validation with either a valid or invalid result.
    internal enum ValidationState: Equatable {
        
        /// The form has not yet been validated.
        case unvalidated
        
        /// A validation pass is currently in progress.
        case validating
        
        /// The form has been validated successfully with no errors.
        case valid
        
        /// The form has been validated and contains one or more errors.
        case invalid
    }
}
