//
//  Request.swift
//  Justaway
//
//  Created by Shinichiro Aska on 9/5/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

extension TwitterAPI {
    
    public class Request {
        
        public let urlRequest: NSURLRequest
        
        init(_ urlRequest: NSURLRequest) {
            self.urlRequest = urlRequest
        }
        
        public func send(completion: CompletionHandler? = nil) -> NSURLSessionDataTask {
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
            let task = session.dataTaskWithRequest(urlRequest) { (responseData, response, error) -> Void in
                dispatch_async(dispatch_get_main_queue(), {
                    completion?(responseData: responseData, response: response, error: error)
                })
            }
            task.resume()
            
            return task
        }
    }
}