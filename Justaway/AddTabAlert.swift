//
//  AddTabAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 2/4/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox
import TwitterAPI

class AddTabAlert {
    class func show(sender: UIView, account: Account) {
        let tabs = account.tabs
        let actionSheet =  UIAlertController(title: "Add Tab", message: nil, preferredStyle: .ActionSheet)
        if tabs.indexOf({ $0.type == .HomeTimline }) == nil {
            actionSheet.addAction(UIAlertAction(title: "Home", style: .Default, handler: { action in
                EventBox.post("addTab", sender: Tab(type: .HomeTimline, userID: "", arguments: [:]))
            }))
        }
        if tabs.indexOf({ $0.type == .Notifications }) == nil {
            if account.exToken.isEmpty {
                actionSheet.addAction(UIAlertAction(title: "Notifications", style: .Default, handler: { action in
                    let alert = UIAlertController(title: "Are you sure you want to use the Notification?", message: "Additional authentication is required.", preferredStyle: .Alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
                        SafariExURLHandler.open({ (account: Account) in
                            EventBox.post("addTab", sender: Tab(type: .Notifications, userID: "", arguments: [:]))
                        })
                    }))
                    alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                    AlertController.showViewController(alert)
                }))
            } else {
                actionSheet.addAction(UIAlertAction(title: "Notifications", style: .Default, handler: { action in
                    EventBox.post("addTab", sender: Tab(type: .Notifications, userID: "", arguments: [:]))
                }))
            }
        }
        if tabs.indexOf({ $0.type == .Mentions }) == nil {
            actionSheet.addAction(UIAlertAction(title: "Mentions", style: .Default, handler: { action in
                EventBox.post("addTab", sender: Tab(type: .Mentions, userID: "", arguments: [:]))
            }))
        }
        if tabs.indexOf({ $0.type == .Favorites }) == nil {
            actionSheet.addAction(UIAlertAction(title: "Likes", style: .Default, handler: { action in
                EventBox.post("addTab", sender: Tab(type: .Favorites, userID: "", arguments: [:]))
            }))
        }
        if tabs.indexOf({ $0.type == .Messages }) == nil {
            if let account = AccountSettingsStore.get()?.account() {
                if let _ = account.client as? OAuthClient {
                    actionSheet.addAction(UIAlertAction(title: "Messages", style: .Default, handler: { action in
                        EventBox.post("addTab", sender: Tab(type: .Messages, userID: "", arguments: [:]))
                    }))
                }
            }
        }
        actionSheet.addAction(UIAlertAction(title: "Lists...", style: .Default, handler: { action in
            ChooseListsViewController.show()
        }))
        actionSheet.addAction(UIAlertAction(title: "Saved Searches...", style: .Default, handler: { action in
            SavedSearchesViewController.show()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        // iPad
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds

        AlertController.showViewController(actionSheet)
    }
}
