import UIKit
import Security

let serviceIdentifier = "info.justaway"
let accessGroup = "info.justaway.Justaway"

class KeychainService: NSObject {
    
    class func remove(key: String) -> Bool {
        let keychainQuery = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrService : serviceIdentifier,
            kSecAttrAccount : key,
            kSecValueData   : NSData() ]
        
        let status: OSStatus = SecItemDelete(keychainQuery as CFDictionaryRef)
        
        return status == noErr
    }
    
    class func save(key: String, data: NSString) -> Bool {
        let dataFromString: NSData = data.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)!
        
        let keychainQuery = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrService : serviceIdentifier,
            kSecAttrAccount : key,
            kSecValueData   : dataFromString ]
        
        SecItemDelete(keychainQuery as CFDictionaryRef)
        
        let status: OSStatus = SecItemAdd(keychainQuery as CFDictionaryRef, nil)
        
        return status == noErr
    }
    
    class func load(key: String) -> NSString {
        let keychainQuery = [
            kSecClass       : kSecClassGenericPassword,
            kSecAttrService : serviceIdentifier,
            kSecAttrAccount : key,
            kSecReturnData  : kCFBooleanTrue,
            kSecMatchLimit  : kSecMatchLimitOne ]
        
        var dataTypeRef :Unmanaged<AnyObject>?
        
        let status: OSStatus = SecItemCopyMatching(keychainQuery, &dataTypeRef)
        
        let opaque = dataTypeRef?.toOpaque()
        
        if let op = opaque? {
            return NSString(data: Unmanaged<NSData>.fromOpaque(op).takeUnretainedValue(), encoding: NSUTF8StringEncoding)
        } else {
            return ""
        }
    }
    
}
