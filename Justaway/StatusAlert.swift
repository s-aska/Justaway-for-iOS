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

    class func show(_ sender: UIView, status: TwitterStatus, full: Bool) {
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
            style: .cancel,
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

    fileprivate class func addDeleteAction(_ actionSheet: UIAlertController, status: TwitterStatus, statusID: String) {
        if let account = AccountSettingsStore.get()?.find(status.user.userID) {
            actionSheet.addAction(UIAlertAction(
                title: "Delete Tweet",
                style: .destructive,
                handler: { action in
                    Twitter.destroyStatus(account, statusID: statusID)
            }))
        }
    }

    fileprivate class func addShareAction(_ actionSheet: UIAlertController, status: TwitterStatus) {
        actionSheet.addAction(UIAlertAction(
            title: "Share",
            style: .default,
            handler: { action in
                let items = [
                    status.text,
                    status.statusURL
                ] as [Any]
                let activityVC = UIActivityViewController(activityItems: items, applicationActivities: nil)
                if let rootVc: UIViewController = UIApplication.shared.keyWindow?.rootViewController {
                    rootVc.present(activityVC, animated: true, completion: nil)
                }
        }))
    }

    fileprivate class func addTranslateAction(_ actionSheet: UIAlertController, status: TwitterStatus) {
        actionSheet.addAction(UIAlertAction(
            title: "Translate",
            style: .default,
            handler: { action in
                let text = status.text as NSString
                let encodeText = text.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? text as String
                let lang = Locale.preferredLanguages[0].components(separatedBy: "-")[0]
                Safari.openURL("https://translate.google.co.jp/#auto/\(lang)/" + (encodeText as String))
                return
        }))
    }

    fileprivate class func addViewRetweets(_ actionSheet: UIAlertController, status: TwitterStatus) {
        actionSheet.addAction(UIAlertAction(
            title: "View Retweets",
            style: .default,
            handler: { action in
                RetweetsViewController.show(status.statusID)
        }))
    }

    fileprivate class func addViewLikes(_ actionSheet: UIAlertController, status: TwitterStatus) {
        guard let account = AccountSettingsStore.get()?.find(status.user.userID), !account.exToken.isEmpty else {
            return
        }
        actionSheet.addAction(UIAlertAction(
            title: "View Likes",
            style: .default,
            handler: { action in
                LikesViewController.show(status)
        }))
    }

    // MARK: - Long tap

    fileprivate class func addReplyAction(_ actionSheet: UIAlertController, status: TwitterStatus) {
        actionSheet.addAction(UIAlertAction(
            title: "Reply",
            style: .default,
            handler: { action in
                Twitter.reply(status)
        }))
    }

    fileprivate class func addFavRTAction(_ actionSheet: UIAlertController, status: TwitterStatus, statusID: String, retweetedStatusID: String?, isFavorite: Bool) {
        if !isFavorite && retweetedStatusID == nil && !status.user.isProtected {
            actionSheet.addAction(UIAlertAction(
                title: "Like & RT",
                style: .default,
                handler: { action in
                    Twitter.createFavorite(statusID)
                    Twitter.createRetweet(statusID)
            }))
        }

        if isFavorite {
            actionSheet.addAction(UIAlertAction(
                title: "Unlike",
                style: .destructive,
                handler: { action in
                    Twitter.destroyFavorite(statusID)
            }))
        } else {
            actionSheet.addAction(UIAlertAction(
                title: "Like",
                style: .default,
                handler: { action in
                    Twitter.createFavorite(statusID)
            }))
        }

        if let retweetedStatusID = retweetedStatusID {
            if retweetedStatusID != "0" {
                actionSheet.addAction(UIAlertAction(
                    title: "Undo Retweet",
                    style: .destructive,
                    handler: { action in
                        Twitter.destroyRetweet(statusID, retweetedStatusID: retweetedStatusID)
                }))
            }
        } else if !status.user.isProtected {
            actionSheet.addAction(UIAlertAction(
                title: "Retweet",
                style: .default,
                handler: { action in
                    Twitter.createRetweet(statusID)
            }))
        }

        actionSheet.addAction(UIAlertAction(
            title: "Quote",
            style: .default,
            handler: { action in
                Twitter.quoteURL(status)
        }))
    }

    fileprivate class func addURLAction(_ actionSheet: UIAlertController, status: TwitterStatus) {
        for url in status.urls {
            if let expandedURL = URL(string: url.expandedURL) {
                actionSheet.addAction(UIAlertAction(
                    title: url.displayURL,
                    style: .default,
                    handler: { action in
                        Safari.openURL(expandedURL)
                        return
                }))
            }
        }
    }

    fileprivate class func addHashTagAction(_ actionSheet: UIAlertController, status: TwitterStatus) {
        for hashtag in status.hashtags {
            actionSheet.addAction(UIAlertAction(
                title: "#" + hashtag.text,
                style: .default,
                handler: { action in
                    SearchViewController.show("#" + hashtag.text)
                    return
            }))
            actionSheet.addAction(UIAlertAction(
                title: "Add to tab #" + hashtag.text,
                style: .default,
                handler: { action in
                    if let settings = AccountSettingsStore.get(), let account = settings.account() {
                        let tabs = account.tabs + [Tab.init(userID: account.userID, keyword: "#" + hashtag.text)]
                        let account = Account(account: account, tabs: tabs)
                        let accounts = settings.accounts.map({ $0.userID == account.userID ? account : $0 })
                        AccountSettingsStore.save(AccountSettings(current: settings.current, accounts: accounts))
                        EventBox.post(eventTabChanged)
                    }
            }))
        }
    }

    fileprivate class func addUserAction(_ actionSheet: UIAlertController, status: TwitterStatus) {
        var users = [status.user] + status.mentions
        if let actionedBy = status.actionedBy {
            users.append(actionedBy)
        }
        var userMap = [String: Bool]()
        for user in users {
            if userMap.index(forKey: user.userID) != nil {
                continue
            }
            userMap.updateValue(true, forKey: user.userID)
            actionSheet.addAction(UIAlertAction(
                title: "@" + user.screenName,
                style: .default,
                handler: { action in
                    ProfileViewController.show(user)
            }))
        }
    }

    fileprivate class func addViaAction(_ actionSheet: UIAlertController, status: TwitterStatus) {
        if let viaURL = status.via.URL {
            actionSheet.addAction(UIAlertAction(
                title: "via " + status.via.name,
                style: .default,
                handler: { action in
                    Safari.openURL(viaURL)
                    return
            }))
        }
    }
}
