//
//  StatusAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/24/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import EventBox

class StatusAlert {

    // MARK: - Public

    class func show(sender: UIView, status: TwitterStatus, full: Bool) {
        let statusID = status.statusID
        let actionSheet = UIAlertController()
        if full {
            actionSheet.message = status.text
        } else {
            actionSheet.title = status.text
            actionSheet.message = "Display all of the menu with a long tap"
        }
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: { action in
        }))
        Twitter.isRetweet(statusID) { (retweetedStatusID) -> Void in
            Twitter.isFavorite(statusID) { (isFavorite) -> Void in

                addDeleteAction(actionSheet, status: status, statusID: statusID)
                addTranslateAction(actionSheet, status: status)
                addShareAction(actionSheet, status: status)

                if status.retweetCount > 0 {
                    addViewRetweets(actionSheet, status: status)
                }

                if status.favoriteCount > 0 {
                    addViewLikes(actionSheet, status: status)
                }

                if full {
                     addReplyAction(actionSheet, status: status)
                     addFavRTAction(actionSheet, status: status, statusID: statusID, retweetedStatusID: retweetedStatusID, isFavorite: isFavorite)
                     addURLAction(actionSheet, status: status)
                     addHashTagAction(actionSheet, status: status)
                     addUserAction(actionSheet, status: status)
                     addViaAction(actionSheet, status: status)
                }

                // iPad
                actionSheet.popoverPresentationController?.sourceView = sender
                actionSheet.popoverPresentationController?.sourceRect = sender.bounds

                AlertController.showViewController(actionSheet)
            }
        }
    }

    // MARK: - Private

    private class func addDeleteAction(actionSheet: UIAlertController, status: TwitterStatus, statusID: String) {
        if let account = AccountSettingsStore.get()?.find(status.user.userID) {
            actionSheet.addAction(UIAlertAction(
                title: "Delete Tweet",
                style: .Destructive,
                handler: { action in
                    Twitter.destroyStatus(account, statusID: statusID)
            }))
        }
    }

    private class func addShareAction(actionSheet: UIAlertController, status: TwitterStatus) {
        actionSheet.addAction(UIAlertAction(
            title: "Share",
            style: .Default,
            handler: { action in
                let items = [
                    status.text,
                    status.statusURL
                ]
                let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                if let rootVc: UIViewController = UIApplication.sharedApplication().keyWindow?.rootViewController {
                    rootVc.presentViewController(activityVC, animated: true, completion: nil)
                }
        }))
    }

    private class func addTranslateAction(actionSheet: UIAlertController, status: TwitterStatus) {
        actionSheet.addAction(UIAlertAction(
            title: "Translate",
            style: .Default,
            handler: { action in
                let text = status.text as NSString
                let encodeText = text.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) ?? text
                let lang = NSLocale.preferredLanguages()[0].componentsSeparatedByString("-")[0]
                Safari.openURL("https://translate.google.co.jp/#auto/\(lang)/" + (encodeText as String))
                return
        }))
    }

    private class func addViewRetweets(actionSheet: UIAlertController, status: TwitterStatus) {
        actionSheet.addAction(UIAlertAction(
            title: "View Retweets",
            style: .Default,
            handler: { action in
                RetweetsViewController.show(status.statusID)
        }))
    }

    private class func addViewLikes(actionSheet: UIAlertController, status: TwitterStatus) {
        guard let account = AccountSettingsStore.get()?.find(status.user.userID) where !account.exToken.isEmpty else {
            return
        }
        actionSheet.addAction(UIAlertAction(
            title: "View Likes",
            style: .Default,
            handler: { action in
                LikesViewController.show(status)
        }))
    }

    // MARK: - Long tap

    private class func addReplyAction(actionSheet: UIAlertController, status: TwitterStatus) {
        actionSheet.addAction(UIAlertAction(
            title: "Reply",
            style: .Default,
            handler: { action in
                Twitter.reply(status)
        }))
    }

    private class func addFavRTAction(actionSheet: UIAlertController, status: TwitterStatus, statusID: String, retweetedStatusID: String?, isFavorite: Bool) {
        if !isFavorite && retweetedStatusID == nil && !status.user.isProtected {
            actionSheet.addAction(UIAlertAction(
                title: "Like & RT",
                style: .Default,
                handler: { action in
                    Twitter.createFavorite(statusID)
                    Twitter.createRetweet(statusID)
            }))
        }

        if isFavorite {
            actionSheet.addAction(UIAlertAction(
                title: "Unlike",
                style: .Destructive,
                handler: { action in
                    Twitter.destroyFavorite(statusID)
            }))
        } else {
            actionSheet.addAction(UIAlertAction(
                title: "Like",
                style: .Default,
                handler: { action in
                    Twitter.createFavorite(statusID)
            }))
        }

        if let retweetedStatusID = retweetedStatusID {
            if retweetedStatusID != "0" {
                actionSheet.addAction(UIAlertAction(
                    title: "Undo Retweet",
                    style: .Destructive,
                    handler: { action in
                        Twitter.destroyRetweet(statusID, retweetedStatusID: retweetedStatusID)
                }))
            }
        } else if !status.user.isProtected {
            actionSheet.addAction(UIAlertAction(
                title: "Retweet",
                style: .Default,
                handler: { action in
                    Twitter.createRetweet(statusID)
            }))
        }

        actionSheet.addAction(UIAlertAction(
            title: "Quote",
            style: .Default,
            handler: { action in
                Twitter.quoteURL(status)
        }))
    }

    private class func addURLAction(actionSheet: UIAlertController, status: TwitterStatus) {
        for url in status.urls {
            if let expandedURL = NSURL(string: url.expandedURL) {
                actionSheet.addAction(UIAlertAction(
                    title: url.displayURL,
                    style: .Default,
                    handler: { action in
                        Safari.openURL(expandedURL)
                        return
                }))
            }
        }
    }

    private class func addHashTagAction(actionSheet: UIAlertController, status: TwitterStatus) {
        for hashtag in status.hashtags {
            actionSheet.addAction(UIAlertAction(
                title: "#" + hashtag.text,
                style: .Default,
                handler: { action in
                    SearchViewController.show("#" + hashtag.text)
                    return
            }))
            actionSheet.addAction(UIAlertAction(
                title: "Add to tab #" + hashtag.text,
                style: .Default,
                handler: { action in
                    if let settings = AccountSettingsStore.get() {
                        let tabs = settings.account().tabs + [Tab.init(userID: settings.account().userID, keyword: "#" + hashtag.text)]
                        let account = Account(account: settings.account(), tabs: tabs)
                        let accounts = settings.accounts.map({ $0.userID == account.userID ? account : $0 })
                        AccountSettingsStore.save(AccountSettings(current: settings.current, accounts: accounts))
                        EventBox.post(eventTabChanged)
                    }
            }))
        }
    }

    private class func addUserAction(actionSheet: UIAlertController, status: TwitterStatus) {
        var users = [status.user] + status.mentions
        if let actionedBy = status.actionedBy {
            users.append(actionedBy)
        }
        var userMap = [String: Bool]()
        for user in users {
            if userMap.indexForKey(user.userID) != nil {
                continue
            }
            userMap.updateValue(true, forKey: user.userID)
            actionSheet.addAction(UIAlertAction(
                title: "@" + user.screenName,
                style: .Default,
                handler: { action in
                    ProfileViewController.show(user)
            }))
        }
    }

    private class func addViaAction(actionSheet: UIAlertController, status: TwitterStatus) {
        if let viaURL = status.via.URL {
            actionSheet.addAction(UIAlertAction(
                title: "via " + status.via.name,
                style: .Default,
                handler: { action in
                    Safari.openURL(viaURL)
                    return
            }))
        }
    }
}
