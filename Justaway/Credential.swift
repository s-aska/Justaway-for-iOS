//
//  Credential.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/17/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import Accounts
import OAuthSwift
import Accounts
import Social

public protocol TwitterAPICredential {
    func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> TwitterAPI.Request
    var type: TwitterAPI.CredentialType { get }
}

extension TwitterAPICredential {
    func streaming(url: NSURL, parameters: Dictionary<String, String> = [:]) -> TwitterAPI.StreamingRequest {
        return TwitterAPI.StreamingRequest(self.request("GET", url: url, parameters: parameters).urlRequest)
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

extension TwitterAPI {
    public class CredentialOAuth: TwitterAPICredential {
        let consumerKey: String
        let consumerSecret: String
        let accessToken: String
        let accessTokenSecret: String
        
        init (consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) {
            self.consumerKey = consumerKey
            self.consumerSecret = consumerSecret
            self.accessToken = accessToken
            self.accessTokenSecret = accessTokenSecret
        }
        
        public var type: TwitterAPI.CredentialType {
            return .OAuth
        }
        
        public func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> TwitterAPI.Request {
            let client = OAuthSwiftClient(
                consumerKey: self.consumerKey,
                consumerSecret: self.consumerSecret,
                accessToken: self.accessToken,
                accessTokenSecret: self.accessTokenSecret)
            
            let authorization = OAuthSwiftClient.authorizationHeaderForMethod(method, url: url, parameters: parameters, credential: client.credential)
            let headers = ["Authorization": authorization]
            
            let request: NSURLRequest
            do {
                request = try OAuthSwiftHTTPRequest.makeRequest(
                    url, method: method, headers: headers, parameters: parameters, dataEncoding: NSUTF8StringEncoding, encodeParameters: true)
            } catch let error as NSError {
                fatalError("TwitterAPIOAuthClient#request invalid request error:\(error.description)")
            }
            
            return TwitterAPI.Request(request)
        }
    }
}

extension TwitterAPI {
    public class CredentialAccount: TwitterAPICredential {
        let account: ACAccount
        
        init (account: ACAccount) {
            self.account = account
        }
        
        public var type: TwitterAPI.CredentialType {
            return .Account
        }
        
        public func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> TwitterAPI.Request {
            let requestMethod: SLRequestMethod = method == "GET" ? .GET : .POST
            let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: requestMethod, URL: url, parameters: parameters)
            socialRequest.account = account
            let request = socialRequest.preparedURLRequest()
            return TwitterAPI.Request(request)
        }
    }
}
