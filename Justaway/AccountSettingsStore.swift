import Foundation

class AccountSettingsCache {
    struct Static {
        static let instance: AccountSettingsCache = AccountSettingsCache()
    }
    class var sharedInstance: AccountSettingsCache {
        return Static.instance
    }
    private var settings: AccountSettings?
}

class AccountSettingsStore {
    
    // MARK: - Types
    
    struct Constants {
        static let keychainKey = "AccountService"
    }
    
    class func get() -> AccountSettings? {
        if let settings = AccountSettingsCache.sharedInstance.settings {
            return settings
        } else {
            return load()
        }
    }
    
    // MARK: - Public Methods
    
    class func save(settings: AccountSettings) -> Bool {
        assert(settings.accounts.count > 0, "settings.accounts.count is zero")
        assert(settings.accounts.count > settings.current, "current out of range")
        
        AccountSettingsCache.sharedInstance.settings = settings
        
        let data = NSJSONSerialization.dataWithJSONObject(settings.dictionaryValue, options: nil, error: nil)!
        
        return Keychain.save(Constants.keychainKey, data: data)
    }
    
    class func load() -> AccountSettings? {
        if let data = Keychain.load(Constants.keychainKey) {
            if let json: AnyObject = NSJSONSerialization.JSONObjectWithData(data, options: nil, error: nil) {
                AccountSettingsCache.sharedInstance.settings = AccountSettings(json as NSDictionary)
            }
        }
        
        return AccountSettingsCache.sharedInstance.settings
    }
    
    class func clear() {
        AccountSettingsCache.sharedInstance.settings = nil
        
        Keychain.delete(Constants.keychainKey)
    }
    
}
