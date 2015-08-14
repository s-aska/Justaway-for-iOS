//
//  TwitterAPIOAuthClient.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/14/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import OAuthSwift

class TwitterAPIOAuthClient {
    class func request(accessToken: String, accessTokenSecret: String, method: String, url: NSURL, parameters: Dictionary<String, String>) -> NSURLRequest {
        let credential = OAuthSwiftCredential(consumer_key: TwitterConsumerKey, consumer_secret: TwitterConsumerSecret)
        credential.oauth_token = accessToken
        credential.oauth_token_secret = accessTokenSecret
        
        let authorization = OAuthSwiftClient.authorizationHeaderForMethod(method, url: url, parameters: parameters, credential: credential)
        let request = NSMutableURLRequest(URL: url)
        request.HTTPMethod = method
        request.setValue(authorization, forHTTPHeaderField: "Authorization")
        
        if parameters.count > 0 {
            if let urlComponent = NSURLComponents(URL: url, resolvingAgainstBaseURL: true) {
                var queryItems = [NSURLQueryItem]()
                for (key, value) in parameters {
                    queryItems.append(NSURLQueryItem(name: key, value: value))
                }
                urlComponent.queryItems = queryItems
                request.URL = urlComponent.URL
                
                let charset = CFStringConvertEncodingToIANACharSetName(CFStringConvertNSStringEncodingToEncoding(NSUTF8StringEncoding))
                request.setValue("application/x-www-form-urlencoded; charset=\(charset)", forHTTPHeaderField: "Content-Type")
            } else {
                assertionFailure()
            }
        }
        
        return request
    }
}
