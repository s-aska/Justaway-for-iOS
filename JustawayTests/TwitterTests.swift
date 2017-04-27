import Foundation
import UIKit
import XCTest

class TwitterTests: XCTestCase {
    
    func testTwitterDate() {
        XCTAssertEqual(TwitterDate("Wed Jun 06 20:07:10 +0900 2012").absoluteString, "2012/06/06 20:07:10")
        XCTAssertEqual(TwitterDate(Date(timeIntervalSinceNow: -3)).relativeString, "3s")
        XCTAssertEqual(TwitterDate(Date(timeIntervalSinceNow: -3 * 60)).relativeString, "3m")
        XCTAssertEqual(TwitterDate(Date(timeIntervalSinceNow: -3 * 60 * 60)).relativeString, "3h")
        XCTAssertEqual(TwitterDate(Date(timeIntervalSinceNow: -3 * 60 * 60 * 24)).relativeString, "3d")
        XCTAssertEqual(TwitterDate(Date(timeIntervalSinceNow: -999 * 60 * 60 * 24)).relativeString, "999d")
        XCTAssertEqual(TwitterDate(Date(timeIntervalSinceNow: -1000 * 60 * 60 * 24)).relativeString, "2y")
    }
    
    func testTwitterVia() {
        let via = TwitterVia("<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>")
        XCTAssertEqual(via.name, "Twitter Web Client")
        XCTAssertEqual((via.URL?.absoluteString)!, "http://twitter.com")
        XCTAssertEqual(TwitterVia("Web").name, "Web")
    }
    
}
