import Foundation
import UIKit
import XCTest

class TwitterTests: XCTestCase {
    
    func testTwitterDate() {
        XCTAssertEqual(TwitterDate.absolute(TwitterDate.dateFromString("Wed Jun 06 20:07:10 +0900 2012")), "2012/06/06 20:07:10")
        XCTAssertEqual(TwitterDate.relative(NSDate(timeIntervalSinceNow: -3)), "3s")
        XCTAssertEqual(TwitterDate.relative(NSDate(timeIntervalSinceNow: -3 * 60)), "3m")
        XCTAssertEqual(TwitterDate.relative(NSDate(timeIntervalSinceNow: -3 * 60 * 60)), "3h")
        XCTAssertEqual(TwitterDate.relative(NSDate(timeIntervalSinceNow: -3 * 60 * 60 * 24)), "3d")
    }
    
    func testTwitterVia() {
        XCTAssertEqual(TwitterVia.clientName("<a href=\"http://twitter.com\" rel=\"nofollow\">Twitter Web Client</a>"), "Twitter Web Client")
        XCTAssertEqual(TwitterVia.clientName("Web"), "Web")
    }
    
}
