//
//  TwitterAPISocialClient.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/15/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import Accounts
import Social

public class TwitterAPISocialClient {
    public class func request(account: ACAccount, method: String, url: NSURL, parameters: Dictionary<String, String>) -> NSURLRequest {
        let requestMethod: SLRequestMethod = method == "GET" ? .GET : .POST
        let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: requestMethod, URL: url, parameters: parameters)
        socialRequest.account = account
        let request = socialRequest.preparedURLRequest()
        return request
    }
}
