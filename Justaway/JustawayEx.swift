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
    static var successCallback: ((_ account: Account) -> ())?

    class func open(_ successCallback: ((_ account: Account) -> ())? = nil) {
        SafariExURLHandler.oAuthViewController = Safari.openURL(URL(string: "https://justaway.info/signin/")!)
        SafariExURLHandler.successCallback = successCallback
    }

    class func callback(_ url: URL) {
        let exToken = url.lastPathComponent
        let array = exToken.characters.split(separator: "-", maxSplits: 2, omittingEmptySubsequences: true)
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
            SafariExURLHandler.oAuthViewController?.dismiss(animated: true, completion: {
                SafariExURLHandler.successCallback?(newAccount)
                MessageAlert.show("Notification started", message: "Notification you will receive when you are not running Justaway.")
            })
        } else {
            SafariExURLHandler.oAuthViewController?.dismiss(animated: true, completion: {
                ErrorAlert.show("Missing Account", message: "Please refer to the first account registration.")
            })
        }
    }
}
