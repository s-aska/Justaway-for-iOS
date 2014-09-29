import Foundation

class AccountService {
    
    struct Constants {
        static let Keychain = "AccountService"
        static let Current = "current"
        static let Accounts = "accounts"
    }
    
    class func save(current: NSNumber, accounts: Array<Account>) -> Bool {
        let dictionary = [
            Constants.Current  : current,
            Constants.Accounts : accounts.map({ (a) in a.toDictionary() })
        ]
        
        let data = NSJSONSerialization.dataWithJSONObject(dictionary, options: nil, error: nil)!
        
        return KeychainService.save(Constants.Keychain, data: data)
    }
    
    class func load() -> (NSNumber, Array<Account>) {
        let data = KeychainService.load(Constants.Keychain)
        
        if data == nil {
            return (-1, Array<Account>())
        }
        
        let json :AnyObject! = NSJSONSerialization.JSONObjectWithData(data!, options: nil, error: nil)
        
        let current = json[Constants.Current] as NSNumber
        
        var accounts :Array<Account> = (json[Constants.Accounts] as [NSDictionary]).map({ (d) in Account(dictionary: d) })
        
        return (current, accounts)
    }
    
    class func clear() {
        KeychainService.remove(Constants.Keychain)
    }
    
}
