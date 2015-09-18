//
//  TwitterAPI.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/14/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import OAuthSwift
import Accounts
import Social

public class TwitterAPI {
    
    public typealias ProgressHandler = (data: NSData) -> Void
    public typealias CompletionHandler = (responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void
    
    public class func client(consumerKey consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) -> TwitterAPIClient {
        return TwitterAPI.ClientOAuth(consumerKey: consumerKey, consumerSecret: consumerSecret, accessToken: accessToken, accessTokenSecret: accessTokenSecret)
    }
    
    public class func client(account account: ACAccount) -> TwitterAPIClient {
        return TwitterAPI.ClientAccount(account: account)
    }
    
    public class func client(serializedString string: String) -> TwitterAPIClient {
        switch string {
        case let string where string.hasPrefix(TwitterAPI.ClientOAuth.serializeIdentifier):
            return TwitterAPI.ClientOAuth(serializedString: string)
        case let string where string.hasPrefix(TwitterAPI.ClientAccount.serializeIdentifier):
            return TwitterAPI.ClientAccount(serializedString: string)
        default:
            fatalError("invalid serializedString:\(string)")
        }
    }
}
