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

public class TwitterAPI {
    
    public typealias DataHandler = (data: NSData) -> Void
    public typealias JsonHandler = (json: [String: AnyObject]) -> Void
    public typealias JsonArrayHandler = (array: [[String: AnyObject]]) -> Void
    public typealias CompletionHandler = (response: NSHTTPURLResponse?, responseData: NSData?, error: NSError?) -> Void
    
    public class func send(request: NSURLRequest) {
        
    }
    
    public class func connectStreaming(request: NSURLRequest, success: JsonHandler, completion: CompletionHandler? = nil) -> TwitterAPIStreamingRequest {
        let streamingRequest = TwitterAPIStreamingRequest(request)
        streamingRequest.dataHandler = toDataHandler(success)
        streamingRequest.completionHandler = completion
        streamingRequest.start()
        return streamingRequest
    }
    
    public class func toDataHandler(handler: JsonHandler) -> DataHandler {
        let dataHander: DataHandler = { (data: NSData) in
            do {
                let json: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                if let dictionary = json as? [String: AnyObject] {
                    handler(json: dictionary)
                }
            } catch let error as NSError {
                NSLog("[toDataHandler] invalid data error:\(error.debugDescription)")
            } catch _ {
                NSLog("[toDataHandler] invalid data uknown error")
            }
        }
        return dataHander
    }
}

public protocol TwitterAPICredential {
    func request(method: String, url: NSURL, parameters: Dictionary<String, String>) throws -> NSURLRequest
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
    
    public func request(method: String, url: NSURL, parameters: Dictionary<String, String>) throws -> NSURLRequest {
        let clinet = OAuthSwiftClient(consumerKey: self.consumerKey, consumerSecret: self.consumerSecret, accessToken: self.accessToken, accessTokenSecret: self.accessTokenSecret)
        return try TwitterAPIOAuthClient.request(clinet, method: method, url: url, parameters: parameters)
    }
}

public class TwitterAPICredentialSocial: TwitterAPICredential {
    let account: ACAccount
    
    public init (_ account: ACAccount) {
        self.account = account
    }
    
    public func request(method: String, url: NSURL, parameters: Dictionary<String, String>) throws -> NSURLRequest {
        return TwitterAPISocialClient.request(self.account, method: method, url: url, parameters: parameters)
    }
}
