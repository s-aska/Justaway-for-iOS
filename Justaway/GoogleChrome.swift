//
//  GoogleChrome.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/18/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class GoogleChrome {
    struct Static {
        private static let source = "Justaway"
        private static var callbackURLString = "justaway://close-browser".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
    }
    
    class func openURL(url: NSURL) {
        if UIApplication.sharedApplication().canOpenURL(NSURL(string: "googlechrome-x-callback://")!) {
            openChromeURL(url)
        } else {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    class func openChromeURL(url: NSURL) {
        let scheme = url.scheme
        if scheme == "http" || scheme == "https" {
            if let openURLString = url.absoluteString?.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
                let chromeURLString = String(format: "googlechrome-x-callback://x-callback-url/open/?x-source=%@&x-success=%@&url=%@", arguments: [
                    Static.source,
                    Static.callbackURLString,
                    openURLString])
                if let chromeURL = NSURL(string: chromeURLString) {
                    UIApplication.sharedApplication().openURL(chromeURL)
                }
            }
        }
    }
}
