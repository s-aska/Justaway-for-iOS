import Foundation

class AccountSettings {
    
    // MARK: - Types
    
    struct Constants {
        static let accounts = "accounts"
        static let current = "current"
    }
    
    // MARK: - Properties
    
    let accounts: Array<Account>
    let current: Int
    
    // MARK: - Initializers
    
    init(current: Int, accounts: Array<Account>) {
        self.current = current
        self.accounts = accounts
    }
    
    init(_ dictionary: NSDictionary) {
        self.current = dictionary[Constants.current] as Int
        self.accounts = (dictionary[Constants.accounts] as [NSDictionary]).map({ d in Account(d) })
    }
    
    // MARK: - Public Methods
    
    func account() -> Account {
        return accounts[current]
    }
    
    func account(index: Int) -> Account {
        return accounts[index]
    }
    
    func toDictionary() -> NSDictionary {
        return [
            Constants.current  : current,
            Constants.accounts : accounts.map({ a in a.toDictionary() })
        ]
    }
    
}
