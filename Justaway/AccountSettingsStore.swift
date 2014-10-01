import Foundation

class AccountSettingsStore {
    
    // MARK: - Types
    
    struct Constants {
        static let keychainKey = "AccountService"
    }
    
    // MARK: - Public Methods
    
    class func save(settings: AccountSettings) -> Bool {
        let data = NSJSONSerialization.dataWithJSONObject(settings.toDictionary(), options: nil, error: nil)!
        
        return Keychain.save(Constants.keychainKey, data: data)
    }
    
    class func load() -> AccountSettings? {
        let data = Keychain.load(Constants.keychainKey)
        
        if data == nil {
            return nil
        }
        
        let json :AnyObject! = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil)
        
        return AccountSettings(json as NSDictionary)
    }
    
    class func clear() {
        Keychain.remove(Constants.keychainKey)
    }
    
}
