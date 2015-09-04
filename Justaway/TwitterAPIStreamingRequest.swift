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
    
    public var session: NSURLSession?
    public var task: NSURLSessionDataTask?
    public let request: NSURLRequest
    public var response: NSURLResponse!
    public let scanner = MutableDataScanner(delimiter: "\r\n")
    public var progressHandler: TwitterAPI.ProgressHandler?
    public var completionHandler: TwitterAPI.CompletionHandler?
    
    public init(_ request: NSURLRequest) {
        self.request = request
    }
    
    public func start() {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        self.session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        self.task = self.session?.dataTaskWithRequest(self.request)
        self.task?.resume()
    }
    
    public func stop() {
        self.task?.cancel()
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
        dispatch_sync(serial) {
            self.scanner.appendData(data)
            while let data = self.scanner.next() {
                if data.length > 0 {
                    self.progressHandler?(data: data)
                }
            }
        }
    }
    
    public func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
        self.response = response
        if let httpURLResponse = response as? NSHTTPURLResponse {
            if httpURLResponse.statusCode == 200 {
                completionHandler(NSURLSessionResponseDisposition.Allow)
            }
        }
    }
    
    public func URLSession(session: NSURLSession, didReceiveChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if challenge.protectionSpace.host == "userstream.twitter.com" {
                completionHandler(
                    NSURLSessionAuthChallengeDisposition.UseCredential,
                    NSURLCredential(forTrust: challenge.protectionSpace.serverTrust!))
            }
        }
    }
    
    public func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
        dispatch_async(dispatch_get_main_queue(), {
            self.completionHandler?(responseData: self.scanner.data, response: self.response, error: error)
        })
    }
}
