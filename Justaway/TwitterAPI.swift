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
    
    public class func send(request: NSURLRequest, completion: CompletionHandler) -> NSURLSessionDataTask {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        let task = session.dataTaskWithRequest(request, completionHandler: completion)
        task.resume()
        return task
    }
    
    public class func connectStreaming(request: NSURLRequest, progress: ProgressHandler, completion: CompletionHandler? = nil) -> TwitterAPIStreamingRequest {
        let streamingRequest = TwitterAPIStreamingRequest(request)
        streamingRequest.progressHandler = progress
        streamingRequest.completionHandler = completion
        streamingRequest.start()
        return streamingRequest
    }
}
