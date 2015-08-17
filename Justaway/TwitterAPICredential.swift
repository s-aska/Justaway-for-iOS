//
//  TwitterAPICredential.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/17/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import Accounts
import OAuthSwift

public protocol TwitterAPICredential {
    func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> NSURLRequest
}

public class TwitterAPICredentialOAuth: TwitterAPICredential {
    let consumerKey: String
    let consumerSecret: String
    let accessToken: String
    let accessTokenSecret: String
    
    public init (consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) {
        self.consumerKey = consumerKey
        self.consumerSecret = consumerSecret
        self.accessToken = accessToken
        self.accessTokenSecret = accessTokenSecret
    }
    
    public func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> NSURLRequest {
        let clinet = OAuthSwiftClient(consumerKey: self.consumerKey, consumerSecret: self.consumerSecret, accessToken: self.accessToken, accessTokenSecret: self.accessTokenSecret)
        return TwitterAPIOAuthClient.request(clinet, method: method, url: url, parameters: parameters)
    }
}

public class TwitterAPICredentialSocial: TwitterAPICredential {
    let account: ACAccount
    
    public init (_ account: ACAccount) {
        self.account = account
    }
    
    public func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> NSURLRequest {
        return TwitterAPISocialClient.request(self.account, method: method, url: url, parameters: parameters)
    }
}
