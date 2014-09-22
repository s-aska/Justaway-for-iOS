import UIKit
import Security

class KeychainService {
    
    class func save(key: String, data: NSData) -> Bool {
        let keychainQuery = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : key,
            kSecValueData   : data ]
        
        SecItemDelete(keychainQuery as CFDictionaryRef)
        
        let status: OSStatus = SecItemAdd(keychainQuery as CFDictionaryRef, nil)
        
        return status == noErr
    }
    
    class func load(key: String) -> NSData {
        let keychainQuery = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : key,
            kSecReturnData  : kCFBooleanTrue,
            kSecMatchLimit  : kSecMatchLimitOne ]
        
        var dataTypeRef :Unmanaged<AnyObject>?
        
        let status: OSStatus = SecItemCopyMatching(keychainQuery, &dataTypeRef)
        
        let opaque = dataTypeRef?.toOpaque()
        
        if let op = opaque? {
            return Unmanaged<NSData>.fromOpaque(op).takeUnretainedValue()
        } else {
            return NSData()
        }
    }
    
    class func remove(key: String) -> Bool {
        let keychainQuery = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrAccount : key,
            kSecValueData   : NSData() ]
        
        let status: OSStatus = SecItemDelete(keychainQuery as CFDictionaryRef)
        
        return status == noErr
    }
    
}
