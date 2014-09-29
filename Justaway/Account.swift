import Foundation

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
    
    init(dictionary: NSDictionary) {
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
    
}
