import Foundation
import Accounts
import Social

class Account {
    
    // MARK: - Types
    
    struct Constants {
        static let accessToken = "accessToken"
        static let userID = "userID"
        static let screenName = "screenName"
        static let name = "name"
        static let profileImageURL = "profileImageURL"
        static let iOS = "iOS"
    }
    
    // MARK: - Properties
    
    let accessToken: String
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: NSURL
    let iOS: Bool
    
    // MARK: - Initializers
    
    init(accessToken: String, userID: String, screenName: String, name: String, profileImageURL: NSURL, iOS: Bool) {
        self.accessToken = accessToken
        self.userID = userID
        self.screenName = screenName
        self.name = name
        self.profileImageURL = profileImageURL
        self.iOS = iOS
    }
    
    init(_ dictionary: NSDictionary) {
        self.accessToken = dictionary[Constants.accessToken] as String
        self.userID = dictionary[Constants.userID] as String
        self.screenName = dictionary[Constants.screenName] as String
        self.name = dictionary[Constants.name] as String
        self.profileImageURL = NSURL(string: dictionary[Constants.profileImageURL] as String)
        self.iOS = dictionary[Constants.iOS] as Bool
    }
    
    // MARK: - Public Methods
    
    func profileImageBiggerURL() -> NSURL {
        return NSURL(string: profileImageURL.absoluteString!
            .stringByReplacingOccurrencesOfString("_normal", withString: "_bigger", options: nil, range: nil))
    }
    
    func toDictionary() -> NSDictionary {
        return [ Constants.accessToken     : self.accessToken,
                 Constants.userID          : self.userID,
                 Constants.screenName      : self.screenName,
                 Constants.name            : self.name,
                 Constants.profileImageURL : self.profileImageURL.absoluteString!,
                 Constants.iOS             : self.iOS ]
    }
    
    func get(url: NSURL, parameters: NSDictionary?, hander: SLRequestHandler) {
        let req = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .GET, URL: url, parameters: parameters)
        if (iOS) {
            req.account = ACAccountStore().accountWithIdentifier(accessToken)
        } else {
            let accountType = ACAccountStore().accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
            let account = ACAccount(accountType: accountType)
            account.credential = ACAccountCredential(OAuth2Token: "", refreshToken: "", expiryDate: NSDate())
            req.account = account
        }
        req.performRequestWithHandler({
            (data :NSData!, res :NSHTTPURLResponse!, error :NSError!) -> Void in
            NSLog("%@", NSString(data: data, encoding :NSUTF8StringEncoding))
        })
    }
    
}
