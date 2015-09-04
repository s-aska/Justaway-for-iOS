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
    func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> TwitterAPI.Request
}

extension TwitterAPICredential {
    func streaming(url: NSURL, parameters: Dictionary<String, String> = [:]) -> TwitterAPIStreamingRequest {
        return TwitterAPIStreamingRequest(self.request("GET", url: url, parameters: parameters).request)
    }
    
    func get(url: NSURL, parameters: Dictionary<String, String> = [:]) -> TwitterAPI.Request {
        return self.request("GET", url: url, parameters: parameters)
    }
    
    func post(url: NSURL, parameters: Dictionary<String, String> = [:]) -> TwitterAPI.Request {
        return self.request("POST", url: url, parameters: parameters)
    }
    
    func postMedia(data: NSData) -> TwitterAPI.Request {
        let media = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
        let url = NSURL(string: "https://upload.twitter.com/1.1/media/upload.json")!
        return self.post(url, parameters: ["media": media])
    }
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
    
    public func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> TwitterAPI.Request {
        let clinet = OAuthSwiftClient(consumerKey: self.consumerKey, consumerSecret: self.consumerSecret, accessToken: self.accessToken, accessTokenSecret: self.accessTokenSecret)
        return TwitterAPIOAuthClient.request(clinet, method: method, url: url, parameters: parameters)
    }
}

public class TwitterAPICredentialSocial: TwitterAPICredential {
    let account: ACAccount
    
    public init (_ account: ACAccount) {
        self.account = account
    }
    
    public func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> TwitterAPI.Request {
        return TwitterAPISocialClient.request(self.account, method: method, url: url, parameters: parameters)
    }
}
