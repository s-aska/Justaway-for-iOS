import Foundation

class AccountService {
    
    struct KeyConstants {
        static let keychain = "AccountService"
        static let current = "current"
        static let accounts = "accounts"
    }
    
    class func save(current: NSNumber, accounts: Array<Account>) -> Bool {
        let dictionary = [
            KeyConstants.current  : current,
            KeyConstants.accounts : accounts.map({ (account: Account) -> NSDictionary in account.toDictionary() })
        ]
        
        let data = NSJSONSerialization.dataWithJSONObject(dictionary, options: nil, error: nil)!
        
        return KeychainService.save(KeyConstants.keychain, data: data)
    }
    
    class func load() -> (NSNumber, Array<Account>) {
        let data = KeychainService.load(KeyConstants.keychain)
        
        if data == nil {
            return (-1, Array<Account>())
        }
        
        let json :AnyObject! = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments, error: nil) as? NSDictionary
        
        let current = json[KeyConstants.current] as NSNumber
        
        var accounts :Array<Account> = (json[KeyConstants.accounts] as [NSDictionary]).map({
            (dictionary: NSDictionary) in
            Account(dictionary: dictionary)
        })
        
        return (current, accounts)
    }
    
    class func clear() {
        KeychainService.remove(KeyConstants.keychain)
    }
    
}
