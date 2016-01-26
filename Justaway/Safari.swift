//
//  Safari.swift
//  Justaway
//
//  Created by Shinichiro Aska on 9/30/15.
//  Copyright © 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import SafariServices
import OAuthSwift
import Async

class Safari {

    static let delegate = SafariDelegate()

    class func openURL(string: String) {
        if let url = NSURL(string: string) {
            openURL(url)
        }
    }

    class func openURL(url: NSURL) -> SFSafariViewController? {
        guard let rootVc = UIApplication.sharedApplication().keyWindow?.rootViewController else {
            return nil
        }
        let vc = SFSafariViewController(URL: url)
        vc.delegate = delegate
        rootVc.presentViewController(vc, animated: true, completion: nil)
        return vc
    }
}

// MARK: - SafariOAuthURLHandler

class SafariOAuthURLHandler: NSObject, OAuthSwiftURLHandlerType {

    static var oAuthViewController: SFSafariViewController?

    func handle(url: NSURL) {
        SafariOAuthURLHandler.oAuthViewController = Safari.openURL(url)
    }

    class func callback(url: NSURL) {
        OAuthSwift.handleOpenURL(url)
        SafariOAuthURLHandler.oAuthViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: SFSafariViewControllerDelegate

class SafariDelegate: NSObject, SFSafariViewControllerDelegate {

    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)

        // bug?
        Async.main(after: 0.05) { () -> Void in
            ThemeController.apply()
        }
    }
}
