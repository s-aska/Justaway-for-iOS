import Foundation
import Accounts
import Social
import SwifteriOS

class Account {
    
    // MARK: - Types
    
    struct Constants {
        static let identifier = "identifier"
        static let key = "key"
        static let secret = "secret"
        static let userID = "user_id"
        static let screenName = "screen_name"
        static let name = "name"
        static let profileImageURL = "profile_image_url"
    }
    
    // MARK: - Properties
    
    let credential: SwifterCredential
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: NSURL
    
    // MARK: - Initializers
    
    init(credential: SwifterCredential, userID: String, screenName: String, name: String, profileImageURL: NSURL) {
        self.credential = credential
        self.userID = userID
        self.screenName = screenName
        self.name = name
        self.profileImageURL = profileImageURL
    }
    
    init(_ dictionary: NSDictionary) {
        self.userID = dictionary[Constants.userID] as String
        self.screenName = dictionary[Constants.screenName] as String
        self.name = dictionary[Constants.name] as String
        self.profileImageURL = NSURL(string: dictionary[Constants.profileImageURL] as String)
        if dictionary[Constants.identifier] != nil {
            let account = ACAccountStore().accountWithIdentifier(dictionary[Constants.identifier] as String)
            self.credential = SwifterCredential(account: account)
        } else {
            let accessToken = SwifterCredential.OAuthAccessToken(key: dictionary[Constants.key] as String, secret: dictionary[Constants.secret] as String)
            self.credential = SwifterCredential(accessToken: accessToken)
        }
    }
    
    // MARK: - Public Methods
    
    func profileImageBiggerURL() -> NSURL {
        return NSURL(string: profileImageURL.absoluteString!
            .stringByReplacingOccurrencesOfString("_normal", withString: "_bigger", options: nil, range: nil))
    }
    
    func toDictionary() -> NSDictionary {
        if let account = credential.account {
            return [ Constants.identifier      : account.identifier,
                     Constants.userID          : self.userID,
                     Constants.screenName      : self.screenName,
                     Constants.name            : self.name,
                     Constants.profileImageURL : self.profileImageURL.absoluteString! ]
        }
        if let accessToken = credential.accessToken {
            return [ Constants.key             : accessToken.key,
                     Constants.secret          : accessToken.secret,
                     Constants.userID          : self.userID,
                     Constants.screenName      : self.screenName,
                     Constants.name            : self.name,
                     Constants.profileImageURL : self.profileImageURL.absoluteString! ]
        }
        assertionFailure("Invalid credential.")
    }
    
    func get(url: NSURL, parameters: NSDictionary?, hander: SLRequestHandler) {
//        let req = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: url, parameters: parameters)
//        if (iOS) {
//            req.account = ACAccountStore().accountWithIdentifier(accessToken)
//        } else {
//            let accountType = ACAccountStore().accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
//            let account = ACAccount(accountType: accountType)
//            account.credential = ACAccountCredential(OAuth2Token: "", refreshToken: "", expiryDate: NSDate())
//            req.account = account
//        }
//        req.performRequestWithHandler({
//            (data :NSData!, res :NSHTTPURLResponse!, error :NSError!) -> Void in
//            NSLog("%@", NSString(data: data, encoding :NSUTF8StringEncoding))
//        })
    }
    
}
