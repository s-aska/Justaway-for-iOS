//
//  JustawayEx.swift
//  Justaway
//
//  Created by Shinichiro Aska on 4/7/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import SafariServices

// MARK: - SafariExURLHandler

class SafariExURLHandler: NSObject {

    static var oAuthViewController: SFSafariViewController?

    class func open() {
        SafariExURLHandler.oAuthViewController = Safari.openURL(NSURL(string: "https://justaway.info/signin/")!)
    }

    class func callback(url: NSURL) {
        guard let exToken = url.lastPathComponent else {
            return
        }
        let array = exToken.characters.split("-", maxSplit: 2, allowEmptySlices: false)
        if array.count != 2 {
            return
        }
        let userId = String(array[0])
        guard let accountSettings = AccountSettingsStore.get() else {
            return
        }
        if let account = accountSettings.find(userId) {
            let newSettings = accountSettings.merge([Account.init(account: account, exToken: exToken)])
            AccountSettingsStore.save(newSettings)
            SafariExURLHandler.oAuthViewController?.dismissViewControllerAnimated(true, completion: {
                MessageAlert.show("!!! Welcome Ex !!!", message: "...")
            })
        } else {
            SafariExURLHandler.oAuthViewController?.dismissViewControllerAnimated(true, completion: {
                ErrorAlert.show("Missing Account", message: "Please refer to the first account registration.")
            })
        }
    }
}
