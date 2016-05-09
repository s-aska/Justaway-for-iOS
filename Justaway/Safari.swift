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
        guard let frontVc = ViewTools.frontViewController() else {
            return nil
        }
        let vc = SFSafariViewController(URL: url)
        vc.delegate = delegate
        frontVc.presentViewController(vc, animated: true, completion: nil)
        return vc
    }
}

// MARK: - SafariOAuthURLHandler

class SafariOAuthURLHandler: NSObject, OAuthSwiftURLHandlerType {

    static var oAuthViewController: SFSafariViewController?

    func handle(url: NSURL) {
        let components = NSURLComponents.init(URL: url, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        components?.queryItems = items + [NSURLQueryItem.init(name: "force_login", value: "true")]
        SafariOAuthURLHandler.oAuthViewController = Safari.openURL(components?.URL ?? url)
    }

    class func callback(url: NSURL) {
        OAuthSwift.handleOpenURL(url)
        SafariOAuthURLHandler.oAuthViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
}

// MARK: SFSafariViewControllerDelegate

class SafariDelegate: NSObject, SFSafariViewControllerDelegate {

    // SFSafariViewController don't set page title to SLComposeServiceViewController's textView.text
    func safariViewController(controller: SFSafariViewController, activityItemsForURL URL: NSURL, title: String?) -> [UIActivity] {
        if let ud = NSUserDefaults.init(suiteName: "group.pw.aska.justaway") {
            ud.setURL(URL, forKey: "shareURL")
            ud.setObject(title ?? "", forKey: "shareTitle")
            ud.synchronize()
        }
        return []
    }

    func safariViewControllerDidFinish(controller: SFSafariViewController) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
}
