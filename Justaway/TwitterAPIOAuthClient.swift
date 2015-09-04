//
//  TwitterAPIOAuthClient.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/14/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import OAuthSwift

public class TwitterAPIOAuthClient {
    public class func request(client: OAuthSwiftClient, method: String, url: NSURL, parameters: Dictionary<String, String>, var headers: [String : String] = [:]) -> TwitterAPI.Request {
        let authorization = OAuthSwiftClient.authorizationHeaderForMethod(method, url: url, parameters: parameters, credential: client.credential)
        headers.updateValue(authorization, forKey: "Authorization")
        let request: NSURLRequest
        do {
            request = try OAuthSwiftHTTPRequest.makeRequest(url, method: method, headers: headers, parameters: parameters, dataEncoding: NSUTF8StringEncoding, encodeParameters: true)
        } catch let error as NSError {
            fatalError("TwitterAPIOAuthClient#request invalid request error:\(error.description)")
        }
        return TwitterAPI.Request(request)
    }
}
