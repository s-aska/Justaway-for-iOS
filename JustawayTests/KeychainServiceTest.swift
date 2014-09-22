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
        
        let saveSuccess = KeychainService.save("accounts", data: "{\"hoge\":foo}")
        XCTAssert(saveSuccess, "save")
        
        let data = KeychainService.load("accounts")
        XCTAssert(data == "{\"hoge\":foo}", "load")
        
        let removeSuccess = KeychainService.remove("accounts")
        XCTAssert(removeSuccess, "remove")
        
        let dataAfterRemove = KeychainService.load("accounts")
        XCTAssert(dataAfterRemove == "", "load after remove")
    }
    
}
