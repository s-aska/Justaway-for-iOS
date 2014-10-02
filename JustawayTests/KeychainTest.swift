import UIKit
import XCTest

class KeychainTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let key = "clearTest"
        let saveData = "{\"hoge\":foo}".toData()
        
        XCTAssert(Keychain.save(key, data: saveData), "save")
        
        let loadData = Keychain.load(key)!
        
        XCTAssert(loadData.length > 0, "load length")
        XCTAssert(loadData.toString() == saveData.toString(), "load data")
        
        XCTAssert(Keychain.remove(key), "remove")
        
        XCTAssert(Keychain.load(key) == nil, "load after remove")
    }
    
    func testClear() {
        let key = "clearTest"
        let data = "clearTestData".toData()
        
        Keychain.save(key, data: data)
        XCTAssert(Keychain.load(key) != nil, "load success before clear")
        
        Keychain.clear()
        XCTAssert(Keychain.load(key) == nil, "load failure after clear")
    }
    
}

extension String {
    func toData() -> NSData {
        return dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
    }
}

extension NSData {
    func toString() -> String {
        return NSString(data: self, encoding: NSUTF8StringEncoding)
    }
}
