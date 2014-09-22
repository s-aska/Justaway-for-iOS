import Foundation

class Account {
    
    // MARK: - Properties
    
    let accessToken: String
    let userID: String
    let screenName: String
    let name: String
    let profileImageURL: NSURL
    
    // MARK: - Initializers
    
    init(accessToken: String, userID: String, screenName: String, name: String, profileImageURL: NSURL) {
        self.accessToken = accessToken
        self.userID = userID
        self.screenName = screenName
        self.name = name
        self.profileImageURL = profileImageURL
    }
    
    // MARK: - Public Methods
    
    func profileImageBiggerURL() -> NSURL {
        return NSURL(string: profileImageURL.absoluteString!
            .stringByReplacingOccurrencesOfString("_normal", withString: "_bigger", options: nil, range: nil))
    }
    
}
