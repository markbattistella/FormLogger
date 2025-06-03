//
// Project: FormLogger
// Author: Mark Battistella
// Website: https://markbattistella.com
//

import SimpleLogger
import Foundation

extension LoggerManager {

    /// A logger configuration that disables all logging.
    ///
    /// No logs will be fetched or exported.
    public static var none: LoggerManager {
        LoggerManager(
            excludeSystemLogs: true,
            filterType: .preset,
            selectedPreset: .minutesFive,
            logLevels: [],
            categoryFilters: []
        )
    }

    /// A logger configuration that includes user logs from the last 1 hour.
    public static var lastHour: LoggerManager {
        LoggerManager(
            excludeSystemLogs: true,
            filterType: .preset,
            selectedPreset: .hourOne,
            logLevels: [.debug, .info, .notice, .error, .fault],
            categoryFilters: []
        )
    }

    /// A logger configuration that includes user logs from the last 12 hours.
    public static var last12Hours: LoggerManager {
        LoggerManager(
            excludeSystemLogs: true,
            filterType: .preset,
            selectedPreset: .hoursTwelve,
            logLevels: [.debug, .info, .notice, .error, .fault],
            categoryFilters: []
        )
    }

    /// A logger configuration that includes user logs from the last 24 hours.
    public static var last24Hours: LoggerManager {
        LoggerManager(
            excludeSystemLogs: true,
            filterType: .preset,
            selectedPreset: .hoursTwentyFour,
            logLevels: [.debug, .info, .notice, .error, .fault],
            categoryFilters: []
        )
    }

    /// A logger configuration that includes both user and system logs from the last 1 hour.
    public static var lastHourWithSystem: LoggerManager {
        LoggerManager(
            excludeSystemLogs: false,
            filterType: .preset,
            selectedPreset: .hourOne,
            logLevels: [.debug, .info, .notice, .error, .fault],
            categoryFilters: []
        )
    }

    /// A logger configuration that includes both user and system logs from the last 12 hours.
    public static var last12HoursWithSystem: LoggerManager {
        LoggerManager(
            excludeSystemLogs: false,
            filterType: .preset,
            selectedPreset: .hoursTwelve,
            logLevels: [.debug, .info, .notice, .error, .fault],
            categoryFilters: []
        )
    }

    /// A logger configuration that includes both user and system logs from the last 24 hours.
    public static var last24HoursWithSystem: LoggerManager {
        LoggerManager(
            excludeSystemLogs: false,
            filterType: .preset,
            selectedPreset: .hoursTwentyFour,
            logLevels: [.debug, .info, .notice, .error, .fault],
            categoryFilters: []
        )
    }

    /// The default logger configuration, equivalent to `lastHour`.
    ///
    /// Excludes system logs and includes logs from the last 1 hour.
    public static var `default`: LoggerManager {
        LoggerManager.lastHour
    }
}
