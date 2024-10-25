import Foundation

enum ToDoDateFormatter {
    static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        return formatter
    }()

    /// Formats an ISO 8601 deadline string into a user-friendly date string
    /// while preserving the timezone information.
    ///
    /// Returns a format like "Jan 1, 2023, 10:35:00 PM (+08:00)" or
    /// "Apr 8, 2024, 11:46:14 AM (+0)".
    ///
    /// - Parameter deadline: An ISO 8601 formatted deadline string, which may include
    ///   a timezone offset (e.g., "2024-04-08T11:46:14.349Z" or "2024-12-14T12:34:56.789+05:30").
    /// - Returns: A formatted string representing the deadline, or an empty string if
    ///   the input is nil or invalid.
    static func formattedDeadline(deadline: String?) -> String {
        guard let deadline else {
            return ""
        }

        let hasTimezone = deadline.hasSuffix("Z") || deadline.contains("+") || deadline.contains("-")
        let timezoneString: String
        let deadlineWithoutTimezone: String

        if hasTimezone {
            if deadline.hasSuffix("Z") {
                timezoneString = "(+0)"
                deadlineWithoutTimezone = String(deadline.dropLast(1)) // Remove the "Z"
            } else {
                let timezoneIndex = deadline.index(deadline.endIndex, offsetBy: -6)
                timezoneString = "(\(deadline[timezoneIndex...]))"
                deadlineWithoutTimezone = String(deadline[..<timezoneIndex])
            }
        } else {
            timezoneString = ""
            deadlineWithoutTimezone = deadline
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        displayFormatter.timeZone = TimeZone(secondsFromGMT: 0)

        guard let date = displayFormatter.date(from: deadlineWithoutTimezone) else {
            return ""
        }

        displayFormatter.dateFormat = "MMM d, yyyy, h:mm:ss a"
        let formattedDate = displayFormatter.string(from: date)

        return "\(formattedDate) \(timezoneString)"
    }
}
