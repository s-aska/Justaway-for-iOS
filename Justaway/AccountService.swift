import Foundation

class AccountService {
    
    // MARK: - Types
    
    struct Constants {
        static let keychain = "AccountService"
    }
    
    // MARK: - Public Methods
    
    class func save(settings: AccountSettings) -> Bool {
        let data = NSJSONSerialization.dataWithJSONObject(settings.toDictionary(), options: nil, error: nil)!
        
        return KeychainService.save(Constants.keychain, data: data)
    }
    
    class func load() -> AccountSettings? {
        let data = KeychainService.load(Constants.keychain)
        
        if data == nil {
            return nil
        }
        
        let json :AnyObject! = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil)
        
        return AccountSettings(json as NSDictionary)
    }
    
    class func clear() {
        KeychainService.remove(Constants.keychain)
    }
    
}
