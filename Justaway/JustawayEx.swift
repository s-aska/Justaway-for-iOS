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
    static var successCallback: ((account: Account) -> ())?

    class func open(successCallback: ((account: Account) -> ())? = nil) {
        SafariExURLHandler.oAuthViewController = Safari.openURL(NSURL(string: "https://justaway.info/signin/")!)
        SafariExURLHandler.successCallback = successCallback
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
            let newAccount = Account(account: account, exToken: exToken)
            let newSettings = accountSettings.merge([newAccount])
            AccountSettingsStore.save(newSettings)
            SafariExURLHandler.oAuthViewController?.dismissViewControllerAnimated(true, completion: {
                SafariExURLHandler.successCallback?(account: newAccount)
                MessageAlert.show("Notification started", message: "Notification you will receive when you are not running Justaway.")
            })
        } else {
            SafariExURLHandler.oAuthViewController?.dismissViewControllerAnimated(true, completion: {
                ErrorAlert.show("Missing Account", message: "Please refer to the first account registration.")
            })
        }
    }
}
