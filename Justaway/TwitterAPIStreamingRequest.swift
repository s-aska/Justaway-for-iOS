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
    private var progressHandler: TwitterAPI.ProgressHandler?
    private var completionHandler: TwitterAPI.CompletionHandler?
    
    public init(_ request: NSURLRequest) {
        self.request = request
    }
    
    public func start() -> TwitterAPIStreamingRequest {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        task = self.session?.dataTaskWithRequest(self.request)
        task?.resume()
        return self
    }
    
    public func stop() {
        task?.cancel()
    }
    
    public func progress(progress: TwitterAPI.ProgressHandler) -> TwitterAPIStreamingRequest {
        progressHandler = progress
        return self
    }
    
    public func completion(completion: TwitterAPI.CompletionHandler) -> TwitterAPIStreamingRequest {
        completionHandler = completion
        return self
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
            } else {
                self.completionHandler?(responseData: self.scanner.data, response: self.response, error: nil)
            }
        } else {
            fatalError("didReceiveResponse is not NSHTTPURLResponse")
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
