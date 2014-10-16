import Foundation
import XCTest

class NotificationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Notification.off(self)
    }
    
    override func tearDown() {
        Notification.off(self)
        super.tearDown()
    }
    
    func testOnMainThread() {
        Notification.onMainThread(self, name: "testOnMainThread", callback: {
            (notification: NSNotification!) in
            
            XCTAssertTrue(NSThread.isMainThread())
        })
        Notification.post("testOnMainThread")
    }
    
    func testOnBackgroundThread() {
        Notification.onBackgroundThread(self, name: "testOnBackgroundThread", callback: {
            (notification: NSNotification!) in
            
            XCTAssertTrue(NSThread.isMainThread() == false)
        })
        Notification.post("testOnBackgroundThread")
    }
    
    func testOff() {
        
        var counter = 0
        
        let callback: (notification: NSNotification!) -> Void = {
            (notification: NSNotification!) in
            
            counter++
            return
        }
        
        Notification.onMainThread(self, name: "testOffCounter", callback: callback)
        
        Notification.post("testOffCounter")
        Notification.post("testOffCounter")
        
        Notification.off(self)
        
        Notification.post("testOffCounter")
        Notification.post("testOffCounter")
        
        Notification.onMainThread(self, name: "testOffCounter", callback: callback)
        
        Notification.post("testOffCounter")
        Notification.post("testOffCounter")
        
        Notification.onMainThread(self, name: "testOffVerify", callback: {
            (notification: NSNotification!) in
            
            XCTAssertEqual(counter, 4)
        })
        Notification.post("testOffVerify")
    }
}
