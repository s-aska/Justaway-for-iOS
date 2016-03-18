//
//  OAuthRequestBuilder.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/18/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation
import Pinwheel
import TwitterAPI

public class OAuthRequestBuilder: PinwheelRequestBuilder {

    public init() {
    }

    public func build(URL: NSURL) -> NSURLRequest {
        if URL.absoluteString.hasPrefix("https://ton.twitter.com/1.1/ton/data/dm/") {
            let request = NSMutableURLRequest(URL: URL)
            if let client = Twitter.client() as? OAuthClient {
                let authorization = client.oAuthCredential.authorizationHeaderForMethod(.GET, url: URL, parameters: [:])
                request.setValue(authorization, forHTTPHeaderField: "Authorization")
            }
            return request
        } else {
            return NSURLRequest(URL: URL)
        }
    }
}
