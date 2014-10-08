import UIKit
import XCTest

class KeychainTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        Keychain.clear()
    }
    
    override func tearDown() {
        Keychain.clear()
        super.tearDown()
    }
    
    func testExample() {
        let key1 = "testExampleKey1"
        let key2 = "testExampleKey2"
        let saveData = "data".dataValue
        
        XCTAssertTrue(Keychain.save(key1, data: saveData))
        XCTAssertTrue(Keychain.save(key2, data: saveData))
        
        XCTAssertTrue(Keychain.load(key1) != nil)
        XCTAssertTrue(Keychain.load(key2) != nil)
        
        let loadData = Keychain.load(key1)!
        
        XCTAssertEqual(loadData.stringValue, saveData.stringValue)
        
        XCTAssertTrue(Keychain.remove(key1))
        
        XCTAssertTrue(Keychain.load(key1) == nil)
        XCTAssertTrue(Keychain.load(key2) != nil)
    }
    
    func testClear() {
        let key = "testClearKey"
        let data = "testClearData".dataValue
        
        Keychain.save(key, data: data)
        XCTAssertTrue(Keychain.load(key) != nil)
        
        Keychain.clear()
        XCTAssertTrue(Keychain.load(key) == nil)
    }
    
}

extension String {
    public var dataValue: NSData {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    }
}

extension NSData {
    public var stringValue: String {
        return NSString(data: self, encoding: NSUTF8StringEncoding)
    }
}
