import UIKit
import XCTest
import SwifteriOS

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
        
        let accessToken = SwifterCredential.OAuthAccessToken(key: "", secret: "")
        let credential = SwifterCredential(accessToken: accessToken)
        let account = Account(credential: credential, userID: "1", screenName: "su_aska", name: "Shinichiro Aska", profileImageURL: NSURL(string: normalURL))
        
        XCTAssert(account.screenName == "su_aska", "Account#init")
        
        XCTAssert(account.profileImageBiggerURL().absoluteString == biggerURL, "Account#profileImageBiggerURL")
        
        let saveSuccess = AccountSettingsStore.save(AccountSettings(current: 0, accounts: [account]))
        
        XCTAssert(saveSuccess, "AccountService#save")
        
        let accountSettings = AccountSettingsStore.load()!
        
        XCTAssert(accountSettings.current == 0, "AccountService#load")
        
        XCTAssert(accountSettings.accounts[0].screenName == account.screenName, "AccountService#load")
        
        XCTAssert(accountSettings.account() === accountSettings.account(0), "accountSettings#account")
        
        AccountSettingsStore.clear()
        
        XCTAssert(AccountSettingsStore.load() == nil, "AccountService#clear")
    }
    
}
