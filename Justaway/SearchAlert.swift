//
//  SearchAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 2/22/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox

class SearchAlert {
    class func show(sender: UIView, keyword: String) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }

        let actionSheet =  UIAlertController(title: "Menu", message: nil, preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Add to tab", style: .Default, handler: { action in
            let tab = Tab.init(userID: account.userID, keyword: keyword)
            let newAccount = Account(account: account, tabs: account.tabs + [tab])
            if let settings = AccountSettingsStore.get() {
                let accounts = settings.accounts.map({ $0.userID == newAccount.userID ? newAccount : $0 })
                AccountSettingsStore.save(AccountSettings(current: settings.current, accounts: accounts))
                EventBox.post(eventTabChanged)
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        // iPad
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds

        AlertController.showViewController(actionSheet)
    }
}
