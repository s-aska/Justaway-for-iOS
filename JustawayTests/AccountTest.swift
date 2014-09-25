import UIKit
import XCTest

class AccountTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testExample() {
        let normalURL = "https://pbs.twimg.com/profile_images/435048335674580992/k2F3sHO2_normal.png"
        let biggerURL = "https://pbs.twimg.com/profile_images/435048335674580992/k2F3sHO2_bigger.png"
        
        let account = Account(accessToken: "dummy", userID: "1", screenName: "su_aska", name: "Shinichiro Aska", profileImageURL: NSURL(string: normalURL), iOS: true)
        
        XCTAssert(account.screenName == "su_aska", "screenName")
        
        XCTAssert(account.profileImageBiggerURL().absoluteString == biggerURL, "profileImageBiggerURL")
        
        let saveSuccess = AccountService.save(0, accounts: [account])
        
        XCTAssert(saveSuccess, "saveSuccess")
        
        let (current, accounts) = AccountService.load()
        
        XCTAssert(current == 0, "loadAccounts current")
        
        XCTAssert(accounts[0].screenName == "su_aska", "loadAccounts screenName")
    }
    
}
