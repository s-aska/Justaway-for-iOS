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
    
    public class Request {
        
        public let request: NSURLRequest
        
        init(_ request: NSURLRequest) {
            self.request = request
        }
        
        public func streaming() -> TwitterAPIStreamingRequest {
            return TwitterAPIStreamingRequest(request)
        }
        
        public func send(completion: CompletionHandler?) -> NSURLSessionDataTask {
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
            let task = session.dataTaskWithRequest(request) { (responseData, response, error) -> Void in
                completion?(responseData: responseData, response: response, error: error)
            }
            task.resume()
            return task
        }
    }
}
