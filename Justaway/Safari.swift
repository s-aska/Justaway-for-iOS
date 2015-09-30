//
//  Safari.swift
//  Justaway
//
//  Created by Shinichiro Aska on 9/30/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import SafariServices

class Safari {
    
    static let delegate = SafariDelegate()
    
    class func openURL(string: String) {
        if let url = NSURL(string: string) {
            openURL(url)
        }
    }
    
    class func openURL(url: NSURL) {
        guard let rootVc = UIApplication.sharedApplication().keyWindow?.rootViewController else {
            return
        }
        let vc = SFSafariViewController(URL: url)
        vc.delegate = delegate
        rootVc.presentViewController(vc, animated: true, completion: nil)
    }
}

class SafariDelegate: NSObject, SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        
        // bug?
        Async.main(after: 0.05) { () -> Void in
            ThemeController.apply()
        }
    }
}
