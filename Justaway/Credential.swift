//
//  Credential.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/17/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import OAuthSwift
import Accounts
import Social

public protocol TwitterAPIClient {
    func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> TwitterAPI.Request
    var credential: TwitterAPI.Credential { get }
}

extension TwitterAPIClient {
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
    public class ClientOAuth: TwitterAPIClient {
        let oAuthCredential: OAuthSwiftCredential
        
        init (consumerKey: String, consumerSecret: String, accessToken: String, accessTokenSecret: String) {
            let credential = OAuthSwiftCredential(consumer_key: consumerKey, consumer_secret: consumerSecret)
            credential.oauth_token = accessToken
            credential.oauth_token_secret = accessTokenSecret
            self.oAuthCredential = credential
        }
        
        public var credential: TwitterAPI.Credential {
            return .OAuth(client: oAuthCredential)
        }
        
        public func request(method: String, url: NSURL, parameters: Dictionary<String, String>) -> TwitterAPI.Request {
            let authorization = OAuthSwiftClient.authorizationHeaderForMethod(method, url: url, parameters: parameters, credential: oAuthCredential)
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
    public class ClientAccount: TwitterAPIClient {
        let account: ACAccount
        
        init (account: ACAccount) {
            self.account = account
        }
        
        public var credential: TwitterAPI.Credential {
            return .Account(account: account)
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
