//
//  TwitterAPI.swift
//  Justaway
//
//  Created by Shinichiro Aska on 8/14/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import OAuthSwift

class TwitterAPI {
    class func send(request: NSURLRequest) {
        
    }
    
    class func request(account: Account, method: String, url: NSURL, parameters: Dictionary<String, String>) -> NSURLRequest {
        return TwitterAPIOAuthClient.request(account.credential.accessToken?.key ?? "", accessTokenSecret: account.credential.accessToken?.secret ?? "", method: method, url: url, parameters: parameters)
    }
}

class TwitterStreamingRequest: NSObject, NSURLConnectionDataDelegate {
    private let serial = dispatch_queue_create("TwitterStreamingRequest", DISPATCH_QUEUE_SERIAL)
    
    let request: NSURLRequest
    var response: NSHTTPURLResponse!
    let finishHander: (TwitterStreamingRequest -> Void)?
    let failureHander: ((request: TwitterStreamingRequest, error: NSError) -> Void)?
    let progressHander: ((NSData) -> Void)
    let progressReader = DelimitedReader(delimiter: "\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
    let receivedData = NSMutableData()
    
    init(request: NSURLRequest, progressHander: ((NSData) -> Void), failureHander: ((request: TwitterStreamingRequest, error: NSError) -> Void)) {
        self.request = request
        self.progressHander = progressHander
        self.failureHander = failureHander
        self.finishHander = nil
    }
    
    func start() {
        dispatch_async(dispatch_get_main_queue()) {
            let connection = NSURLConnection(request: self.request, delegate: self)
            connection?.start()
        }
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        NSLog("didReceiveData data:\(NSString(data: data, encoding: NSUTF8StringEncoding))")
        dispatch_sync(serial) {
            self.receivedData.appendData(data)
            self.progressReader.appendData(data)
            while let data = self.progressReader.readData() {
                if let chunk = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    if chunk.hasPrefix("{") {
                        self.progressHander(data)
                    } else if data.length > 0 {
                        self.receivedData.appendData(data)
                        NSLog("not json data:\(NSString(data: data, encoding: NSUTF8StringEncoding))")
                    }
                }
            }
        }
    }
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        self.failureHander?(request: self, error: error)
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        self.response = response as? NSHTTPURLResponse
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        if self.response.statusCode >= 400 {
            let error = NSError(domain: NSURLErrorDomain, code: self.response.statusCode, userInfo: nil)
            self.failureHander?(request: self, error: error)
            if let receivedBody = NSString(data: self.receivedData, encoding: NSUTF8StringEncoding) {
                NSLog("receivedError:\(receivedBody)")
            }
            return
        }
        
        self.finishHander?(self)
    }
}


