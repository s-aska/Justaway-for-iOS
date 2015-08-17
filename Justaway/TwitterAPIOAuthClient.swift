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
    class func request(client: OAuthSwiftClient, method: String, url: NSURL, parameters: Dictionary<String, String>, var headers: [String : String] = [:]) throws -> NSURLRequest {
        let authorization = OAuthSwiftClient.authorizationHeaderForMethod(method, url: url, parameters: parameters, credential: client.credential)
        headers.updateValue(authorization, forKey: "Authorization")
        return try OAuthSwiftHTTPRequest.makeRequest(url, method: method, headers: headers, parameters: parameters, dataEncoding: NSUTF8StringEncoding, encodeParameters: true)
    }
}
