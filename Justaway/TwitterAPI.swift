//
//  TwitterAPI.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/14/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

public class TwitterAPI {
    public typealias ProgressHandler = (data: NSData) -> Void
    public typealias CompletionHandler = (responseData: NSData?, response: NSURLResponse?, error: NSError?) -> Void
}
