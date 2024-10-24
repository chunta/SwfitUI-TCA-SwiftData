import Foundation

enum DateFormatterHelper {
    static let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFractionalSeconds, .withInternetDateTime]
        return formatter
    }()

    static func formattedDeadline(deadline: String?) -> String {
        guard let deadline, let date = isoDateFormatter.date(from: deadline) else {
            return ""
        }

        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .medium
        displayFormatter.timeZone = TimeZone.current

        let formattedDate = displayFormatter.string(from: date)

        let timeZoneString = if deadline.hasSuffix("Z") {
            ""
        } else {
            " (\(String(deadline.suffix(5))))"
        }

        return "\(formattedDate)\(timeZoneString)"
    }
}
