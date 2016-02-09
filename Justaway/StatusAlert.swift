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
    class func show(sender: UIView, status: TwitterStatus) {
        let statusID = status.statusID
        let actionSheet = UIAlertController()
        actionSheet.message = status.text
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: { action in
                actionSheet.dismissViewControllerAnimated(true, completion: nil)
        }))
        Twitter.isRetweet(statusID) { (retweetedStatusID) -> Void in
            Twitter.isFavorite(statusID) { (isFavorite) -> Void in

                addReplyAction(actionSheet, status: status)
                addShowReplyAction(actionSheet, status: status)
                addFavRTAction(actionSheet, status: status, statusID: statusID, retweetedStatusID: retweetedStatusID, isFavorite: isFavorite)
                addShareAction(actionSheet, status: status)
                addURLAction(actionSheet, status: status)
                addHashTagAction(actionSheet, status: status)
                addUserAction(actionSheet, status: status)
                addViaAction(actionSheet, status: status)
                addDeleteAction(actionSheet, status: status, statusID: statusID)

                // iPad
                actionSheet.popoverPresentationController?.sourceView = sender
                actionSheet.popoverPresentationController?.sourceRect = sender.bounds

                AlertController.showViewController(actionSheet)
            }
        }
    }

    private class func addReplyAction(actionSheet: UIAlertController, status: TwitterStatus) {
        actionSheet.addAction(UIAlertAction(
            title: "Reply",
            style: .Default,
            handler: { action in
                Twitter.reply(status)
        }))
    }

    private class func addShowReplyAction(actionSheet: UIAlertController, status: TwitterStatus) {
        if status.inReplyToStatusID != nil {
            actionSheet.addAction(UIAlertAction(
                title: "Show in Reply to...",
                style: .Default,
                handler: { action in
                    TalkViewController.show(status)
            }))
        }
    }

    private class func addFavRTAction(actionSheet: UIAlertController, status: TwitterStatus, statusID: String, retweetedStatusID: String?, isFavorite: Bool) {
        if !isFavorite && retweetedStatusID == nil {
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
        } else {
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
}
