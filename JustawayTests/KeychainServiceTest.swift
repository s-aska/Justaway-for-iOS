import UIKit
import XCTest

class KeychainServiceTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        
        let saveSuccess = KeychainService.save("accounts", data: "{\"hoge\":foo}".toData())
        XCTAssert(saveSuccess, "save")
        
        let dataAfterSave = KeychainService.load("accounts")
        XCTAssert(dataAfterSave!.length > 0, "load length")
        XCTAssert(dataAfterSave!.toString() == "{\"hoge\":foo}", "load data")
        
        let removeSuccess = KeychainService.remove("accounts")
        XCTAssert(removeSuccess, "remove")
        
        let dataAfterRemove = KeychainService.load("accounts")
        XCTAssert(dataAfterRemove == nil, "load after remove")
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
