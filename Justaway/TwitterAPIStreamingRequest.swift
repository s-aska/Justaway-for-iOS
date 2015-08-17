//
//  TwitterAPIStreamingRequest.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/15/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

public class TwitterAPIStreamingRequest: NSObject, NSURLConnectionDataDelegate {
    
    private let serial = dispatch_queue_create("TwitterStreamingRequest", DISPATCH_QUEUE_SERIAL)
    
    public var connection: NSURLConnection?
    public let request: NSURLRequest
    public var response: NSHTTPURLResponse!
    public let delimitedReader = DelimitedReader(delimiter: "\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
    public var dataHandler: TwitterAPI.DataHandler?
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
            self.delimitedReader.appendData(data)
            while let data = self.delimitedReader.readData() {
                if let chunk = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    if chunk.hasPrefix("{") {
                        self.dataHandler?(data: data)
                    } else if data.length > 0 {
                        NSLog("[didReceiveData] not json data:\(NSString(data: data, encoding: NSUTF8StringEncoding))")
                    }
                }
            }
        }
    }
    
    public func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.completionHandler?(response: nil, responseData: nil, error: error)
        NSLog("[didFailWithError] error:\(error.debugDescription)")
    }
    
    public func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        self.response = response as? NSHTTPURLResponse
    }
    
    public func connectionDidFinishLoading(connection: NSURLConnection) {
        NSLog("[connectionDidFinishLoading] code:\(self.response.statusCode) data:\(NSString(data: self.delimitedReader.buffer, encoding: NSUTF8StringEncoding))")
        self.completionHandler?(response: self.response, responseData: self.delimitedReader.buffer, error: nil)
    }
}
