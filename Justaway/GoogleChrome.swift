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
        private static let callback = "justaway://close-browser".encodeURIComponent()!
        private static let installCheckURL = NSURL(string: "googlechrome-x-callback://")!
        private static let format = "googlechrome-x-callback://x-callback-url/open/?x-source=%@&x-success=%@&url=%@"
    }
    
    class func openURL(url: NSURL) {
        if UIApplication.sharedApplication().canOpenURL(Static.installCheckURL) {
            openChromeURL(url)
        } else {
            UIApplication.sharedApplication().openURL(url)
        }
    }
    
    class func openChromeURL(url: NSURL) {
        if url.scheme == "http" || url.scheme == "https" {
            if let openURLString = url.absoluteString?.encodeURIComponent() {
                let chromeURLString = String(format: Static.format, arguments: [Static.source, Static.callback, openURLString])
                if let chromeURL = NSURL(string: chromeURLString) {
                    UIApplication.sharedApplication().openURL(chromeURL)
                }
            }
        }
    }
}

private extension String {
    func encodeURIComponent() -> String? {
        return self.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
    }
}
