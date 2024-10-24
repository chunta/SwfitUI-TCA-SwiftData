import Foundation

enum ToDoDateFormatter {
    static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        return formatter
    }()

    static func formattedDeadline(deadline: String?) -> String {
        guard let deadline, let date = isoDateFormatter.date(from: deadline) else {
            return ""
        }

        // - dateStyle: .medium formats a date transforming "2024-07-31" to "Jul 31, 2024"
        // - timeStyle: .medium formats the time to something like "12:34 PM"
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .medium

        let formattedDate = displayFormatter.string(from: date)

        let timeZoneString = if deadline.hasSuffix("Z") {
            ""
        } else {
            " (\(String(deadline.suffix(5))))"
        }

        return "\(formattedDate)\(timeZoneString)"
    }
}
