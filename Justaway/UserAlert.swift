//
//  UserAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 6/8/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox

class UserAlert {
    class func show(_ sender: UIView, user: TwitterUser, userFull: TwitterUserFull?, relationship: TwitterRelationship) {
        let actionSheet = UIAlertController()
        actionSheet.title = "@" + user.screenName
        actionSheet.message = user.name
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { action in
                actionSheet.dismiss(animated: true, completion: nil)
        }))

        addTabAction(actionSheet, user: user)

        if AccountSettingsStore.isCurrent(user.userID) {

            // EditProfile

        } else {
            addReplyAction(actionSheet, user: user)
            addMessageAction(actionSheet, user: user, relationship: relationship)
            addFollowAction(actionSheet, user: user, relationship: relationship)
            addNotificationsAction(actionSheet, user: user, relationship: relationship)
            addRetweetsAction(actionSheet, user: user, relationship: relationship)
            addMuteAction(actionSheet, user: user, relationship: relationship)
            addBlockAction(actionSheet, user: user, relationship: relationship)
        }

        if let userFull = userFull {
            addURLAction(actionSheet, user: userFull)
        }

        // iPad
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds

        AlertController.showViewController(actionSheet)
    }

    fileprivate class func addTabAction(_ actionSheet: UIAlertController, user: TwitterUser) {
        actionSheet.addAction(UIAlertAction(
            title: "Add to tab",
            style: .default,
            handler: { action in
                if let settings = AccountSettingsStore.get(), let account = settings.account() {
                    let tab = Tab.init(userID: account.userID, user: user)
                    let tabs = account.tabs + [tab]
                    let account = Account(account: account, tabs: tabs)
                    let accounts = settings.accounts.map({ $0.userID == account.userID ? account : $0 })
                    AccountSettingsStore.save(AccountSettings(current: settings.current, accounts: accounts))
                    EventBox.post(eventTabChanged)
                }
        }))
    }

    fileprivate class func addReplyAction(_ actionSheet: UIAlertController, user: TwitterUser) {
        actionSheet.addAction(UIAlertAction(
            title: "Reply",
            style: .default,
            handler: { action in
                let prefix = "@\(user.screenName) "
                let range = NSRange(location: prefix.characters.count, length: 0)
                EditorViewController.show(prefix, range: range)
        }))
    }

    fileprivate class func addMessageAction(_ actionSheet: UIAlertController, user: TwitterUser, relationship: TwitterRelationship) {
        if relationship.canDM {
            actionSheet.addAction(UIAlertAction(
                title: "Direct Message",
                style: .default,
                handler: { action in
                    let prefix = "D \(user.screenName) "
                    let range = NSRange(location: prefix.characters.count, length: 0)
                    EditorViewController.show(prefix, range: range)
            }))
        }
    }

    fileprivate class func addFollowAction(_ actionSheet: UIAlertController, user: TwitterUser, relationship: TwitterRelationship) {
        if relationship.following {
            actionSheet.addAction(UIAlertAction(
                title: "Unfollow",
                style: .destructive,
                handler: { action in
                    Twitter.unfollow(user.userID)
            }))
        } else {
            actionSheet.addAction(UIAlertAction(
                title: "Follow",
                style: .default,
                handler: { action in
                    Twitter.follow(user.userID)
            }))
        }
    }

    fileprivate class func addNotificationsAction(_ actionSheet: UIAlertController, user: TwitterUser, relationship: TwitterRelationship) {
        if relationship.notificationsEnabled {
            actionSheet.addAction(UIAlertAction(
                title: "Turn off notifications",
                style: .default,
                handler: { action in
                    Twitter.turnOffNotification(user.userID)
            }))
        } else {
            actionSheet.addAction(UIAlertAction(
                title: "Turn on notifications",
                style: .default,
                handler: { action in
                    Twitter.turnOnNotification(user.userID)
            }))
        }
    }

    fileprivate class func addRetweetsAction(_ actionSheet: UIAlertController, user: TwitterUser, relationship: TwitterRelationship) {
        if relationship.wantRetweets {
            actionSheet.addAction(UIAlertAction(
                title: "Turn off retweets",
                style: .default,
                handler: { action in
                    Twitter.turnOffRetweets(user.userID)
            }))
        } else {
            actionSheet.addAction(UIAlertAction(
                title: "Turn on retweets",
                style: .default,
                handler: { action in
                    Twitter.turnOnRetweets(user.userID)
            }))
        }
    }

    fileprivate class func addMuteAction(_ actionSheet: UIAlertController, user: TwitterUser, relationship: TwitterRelationship) {
        if relationship.muting {
            actionSheet.addAction(UIAlertAction(
                title: "Unmute",
                style: .default,
                handler: { action in
                    Twitter.unmute(user.userID)
            }))
        } else {
            actionSheet.addAction(UIAlertAction(
                title: "Mute",
                style: .default,
                handler: { action in
                    Twitter.mute(user.userID)
            }))
        }
    }

    fileprivate class func addBlockAction(_ actionSheet: UIAlertController, user: TwitterUser, relationship: TwitterRelationship) {

        if relationship.blocking {
            actionSheet.addAction(UIAlertAction(
                title: "Unblock",
                style: .default,
                handler: { action in
                    Twitter.unblock(user.userID)
            }))
        } else {
            actionSheet.addAction(UIAlertAction(
                title: "Block",
                style: .default,
                handler: { action in
                    Twitter.block(user.userID)
            }))
        }

        actionSheet.addAction(UIAlertAction(
            title: "Report",
            style: .destructive,
            handler: { action in
                Twitter.reportSpam(user.userID)
        }))
    }

    fileprivate class func addURLAction(_ actionSheet: UIAlertController, user: TwitterUserFull) {
        for url in user.urls {
            if let openURL = URL(string: url.expandedURL) {
                actionSheet.addAction(UIAlertAction(
                    title: url.displayURL,
                    style: .default,
                    handler: { action in
                        Safari.openURL(openURL)
                }))
            }
        }
    }
}
