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

    class func openURL(_ string: String) {
        if let url = URL(string: string) {
            openURL(url)
        }
    }

    class func openURL(_ url: URL) -> SFSafariViewController? {
        guard let frontVc = ViewTools.frontViewController() else {
            return nil
        }
        let vc = SFSafariViewController(url: url)
        vc.delegate = delegate
        frontVc.present(vc, animated: true, completion: nil)
        return vc
    }
}

// MARK: - SafariOAuthURLHandler

class SafariOAuthURLHandler: NSObject, OAuthSwiftURLHandlerType {

    static var oAuthViewController: SFSafariViewController?

    func handle(_ url: URL) {
        var components = URLComponents.init(url: url, resolvingAgainstBaseURL: false)
        let items = components?.queryItems ?? []
        components?.queryItems = items + [URLQueryItem.init(name: "force_login", value: "true")]
        SafariOAuthURLHandler.oAuthViewController = Safari.openURL(components?.url ?? url)
    }

    class func callback(_ url: URL) {
        OAuthSwift.handle(url: url)
        SafariOAuthURLHandler.oAuthViewController?.dismiss(animated: true, completion: nil)
    }
}

// MARK: SFSafariViewControllerDelegate

class SafariDelegate: NSObject, SFSafariViewControllerDelegate {

    // SFSafariViewController don't set page title to SLComposeServiceViewController's textView.text
    func safariViewController(_ controller: SFSafariViewController, activityItemsFor URL: URL, title: String?) -> [UIActivity] {
        if let ud = UserDefaults.init(suiteName: "group.pw.aska.justaway") {
            ud.set(URL, forKey: "shareURL")
            ud.set(title ?? "", forKey: "shareTitle")
            ud.synchronize()
        }
        return []
    }

    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        controller.dismiss(animated: true, completion: nil)
    }
}
