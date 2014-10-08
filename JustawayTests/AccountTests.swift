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
        
        XCTAssertEqual(account.screenName, "su_aska")
        
        XCTAssertEqual(account.profileImageBiggerURL.absoluteString!, biggerURL)
        
        let saveSuccess = AccountSettingsStore.save(AccountSettings(current: 0, accounts: [account]))
        
        XCTAssertTrue(saveSuccess)
        
        let accountSettings = AccountSettingsStore.load()!
        
        XCTAssertEqual(accountSettings.current, 0)
        
        XCTAssertEqual(accountSettings.accounts[0].screenName, account.screenName)
        
        XCTAssertEqual(accountSettings.account().userID, accountSettings.account(0).userID)
        
        AccountSettingsStore.clear()
        
        XCTAssertTrue(AccountSettingsStore.load() == nil)
    }
    
}
