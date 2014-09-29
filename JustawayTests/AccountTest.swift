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
        
        XCTAssert(account.screenName == "su_aska", "Account#init")
        
        XCTAssert(account.profileImageBiggerURL().absoluteString == biggerURL, "Account#profileImageBiggerURL")
        
        let saveSuccess = AccountService.save(AccountSettings(current: 0, accounts: [account]))
        
        XCTAssert(saveSuccess, "AccountService#save")
        
        let accountSettings = AccountService.load()!
        
        XCTAssert(accountSettings.current == 0, "AccountService#load")
        
        XCTAssert(accountSettings.accounts[0].screenName == account.screenName, "AccountService#load")
        
        XCTAssert(accountSettings.account() === accountSettings.account(0), "accountSettings#account")
        
        AccountService.clear()
        
        XCTAssert(AccountService.load() == nil, "AccountService#clear")
    }
    
}
