//
//  TwitterAPIStreamingRequest.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/15/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import MutableDataScanner

public class TwitterAPIStreamingRequest: NSObject, NSURLSessionDataDelegate {
    
    private let serial = dispatch_queue_create("pw.aska.TwitterAPI.TwitterStreamingRequest", DISPATCH_QUEUE_SERIAL)
    
    public var connection: NSURLConnection?
    public let request: NSURLRequest
    public var response: NSURLResponse!
    public let scanner = MutableDataScanner(delimiter: "\r\n")
    public var progressHandler: TwitterAPI.ProgressHandler?
    public var completionHandler: TwitterAPI.CompletionHandler?
    
    public init(_ request: NSURLRequest) {
        self.request = request
    }
    
    public func start() {
        dispatch_async(dispatch_get_main_queue()) {
            self.connection = NSURLConnection(request: self.request, delegate: self)
            self.connection?.start()
        }
    }
    
    public func stop() {
        self.connection?.cancel()
    }
    
    public func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        dispatch_sync(serial) {
            self.scanner.appendData(data)
            while let data = self.scanner.nextLine() {
                if data.length > 0 {
                    self.progressHandler?(data: data)
                } else {
                    NSLog("break line.")
                }
            }
        }
    }
    
    public func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        dispatch_async(dispatch_get_main_queue(), {
            self.completionHandler?(responseData: nil, response: nil, error: error)
        })
    }
    
    public func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        self.response = response
    }
    
    public func connectionDidFinishLoading(connection: NSURLConnection) {
        dispatch_async(dispatch_get_main_queue(), {
            self.completionHandler?(responseData: self.scanner.data, response: self.response, error: nil)
        })
    }
}
