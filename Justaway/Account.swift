import Foundation

class Account {
    
    // MARK: - Types
    
    struct KeyConstants {
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
    
    init(dictionary: NSDictionary) {
        self.accessToken = dictionary[KeyConstants.accessToken] as String
        self.userID = dictionary[KeyConstants.userID] as String
        self.screenName = dictionary[KeyConstants.screenName] as String
        self.name = dictionary[KeyConstants.name] as String
        self.profileImageURL = NSURL(string: dictionary[KeyConstants.profileImageURL] as String)
        self.iOS = dictionary[KeyConstants.iOS] as Bool
    }
    
    // MARK: - Public Methods
    
    func profileImageBiggerURL() -> NSURL {
        return NSURL(string: profileImageURL.absoluteString!
            .stringByReplacingOccurrencesOfString("_normal", withString: "_bigger", options: nil, range: nil))
    }
    
    func toDictionary() -> NSDictionary {
        return [ KeyConstants.accessToken     : self.accessToken,
                 KeyConstants.userID          : self.userID,
                 KeyConstants.screenName      : self.screenName,
                 KeyConstants.name            : self.name,
                 KeyConstants.profileImageURL : self.profileImageURL.absoluteString!,
                 KeyConstants.iOS             : self.iOS ]
    }
    
}
