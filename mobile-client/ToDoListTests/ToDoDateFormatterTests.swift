import Foundation
import Testing
@testable import ToDoList

struct ToDoDateFormatterTests {
    /// Tests formatting of deadlines provided in UTC time zone.
    @Test
    func testDeadlineWithUTCTimeZone() {
        let utcDeadline1 = "2024-04-08T11:46:14.349Z"
        let formattedUtcDeadline1 = ToDoDateFormatter.formattedDeadline(deadline: utcDeadline1)
        #expect(formattedUtcDeadline1 == "Apr 8, 2024, 11:46:14 AM (+0)")

        let utcDeadline2 = "2022-11-08T23:46:00.119Z"
        let formattedUtcDeadline2 = ToDoDateFormatter.formattedDeadline(deadline: utcDeadline2)
        #expect(formattedUtcDeadline2 == "Nov 8, 2022, 11:46:00 PM (+0)")
    }

    /// Tests formatting of deadlines provided in specific time zones.
    @Test
    func testDeadlineWithSpecificTimeZone() {
        let taipeiDeadline = "2023-01-01T22:35:00.000+08:00"
        let formattedTaipeiDeadline = ToDoDateFormatter.formattedDeadline(deadline: taipeiDeadline)
        #expect(formattedTaipeiDeadline == "Jan 1, 2023, 10:35:00 PM (+08:00)")

        let indiaDeadline1 = "2024-12-14T12:34:56.789+05:30"
        let formattedIndiaDeadline1 = ToDoDateFormatter.formattedDeadline(deadline: indiaDeadline1)
        #expect(formattedIndiaDeadline1 == "Dec 14, 2024, 12:34:56 PM (+05:30)")

        let indiaDeadline2 = "2024-12-14T11:59:59.999+05:30"
        let formattedIndiaDeadline2 = ToDoDateFormatter.formattedDeadline(deadline: indiaDeadline2)
        #expect(formattedIndiaDeadline2 == "Dec 14, 2024, 11:59:59 AM (+05:30)")

        let vancouverDeadline = "2024-05-02T18:19:11.199-08:00"
        let formattedVancouverDeadline = ToDoDateFormatter.formattedDeadline(deadline: vancouverDeadline)
        #expect(formattedVancouverDeadline == "May 2, 2024, 6:19:11 PM (-08:00)")
    }
}
