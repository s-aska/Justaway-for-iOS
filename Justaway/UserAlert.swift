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
    class func show(sender: UIView, user: TwitterUserFull, relationship: TwitterRelationship) {
        let actionSheet = UIAlertController()
        actionSheet.title = "@" + user.screenName
        actionSheet.message = user.name
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: { action in
                actionSheet.dismissViewControllerAnimated(true, completion: nil)
        }))

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

        addURLAction(actionSheet, user: user)

        // iPad
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds

        AlertController.showViewController(actionSheet)
    }

    private class func addReplyAction(actionSheet: UIAlertController, user: TwitterUserFull) {
        actionSheet.addAction(UIAlertAction(
            title: "Reply",
            style: .Default,
            handler: { action in
                let prefix = "@\(user.screenName) "
                let range = NSRange.init(location: prefix.characters.count, length: 0)
                EditorViewController.show(prefix, range: range)
        }))
    }

    private class func addMessageAction(actionSheet: UIAlertController, user: TwitterUserFull, relationship: TwitterRelationship) {
        if relationship.followedBy {
            actionSheet.addAction(UIAlertAction(
                title: "Direct Message",
                style: .Default,
                handler: { action in
                    let prefix = "D \(user.screenName) "
                    let range = NSRange.init(location: prefix.characters.count, length: 0)
                    EditorViewController.show(prefix, range: range)
            }))
        }
    }

    private class func addFollowAction(actionSheet: UIAlertController, user: TwitterUserFull, relationship: TwitterRelationship) {
        if relationship.following {
            actionSheet.addAction(UIAlertAction(
                title: "Unfollow",
                style: .Destructive,
                handler: { action in
                    Twitter.unfollow(user.userID)
            }))
        } else {
            actionSheet.addAction(UIAlertAction(
                title: "Follow",
                style: .Default,
                handler: { action in
                    Twitter.follow(user.userID)
            }))
        }
    }

    private class func addNotificationsAction(actionSheet: UIAlertController, user: TwitterUserFull, relationship: TwitterRelationship) {
        if relationship.notificationsEnabled {
            actionSheet.addAction(UIAlertAction(
                title: "Turn off notifications",
                style: .Default,
                handler: { action in
                    Twitter.turnOffNotification(user.userID)
            }))
        } else {
            actionSheet.addAction(UIAlertAction(
                title: "Turn on notifications",
                style: .Default,
                handler: { action in
                    Twitter.turnOnNotification(user.userID)
            }))
        }
    }

    private class func addRetweetsAction(actionSheet: UIAlertController, user: TwitterUserFull, relationship: TwitterRelationship) {
        if relationship.wantRetweets {
            actionSheet.addAction(UIAlertAction(
                title: "Turn off retweets",
                style: .Default,
                handler: { action in
                    Twitter.turnOffRetweets(user.userID)
            }))
        } else {
            actionSheet.addAction(UIAlertAction(
                title: "Turn on retweets",
                style: .Default,
                handler: { action in
                    Twitter.turnOnRetweets(user.userID)
            }))
        }
    }

    private class func addMuteAction(actionSheet: UIAlertController, user: TwitterUserFull, relationship: TwitterRelationship) {
        if relationship.muting {
            actionSheet.addAction(UIAlertAction(
                title: "Unmute",
                style: .Default,
                handler: { action in
                    Twitter.unmute(user.userID)
            }))
        } else {
            actionSheet.addAction(UIAlertAction(
                title: "Mute",
                style: .Default,
                handler: { action in
                    Twitter.mute(user.userID)
            }))
        }
    }

    private class func addBlockAction(actionSheet: UIAlertController, user: TwitterUserFull, relationship: TwitterRelationship) {

        if relationship.blocking {
            actionSheet.addAction(UIAlertAction(
                title: "Unblock",
                style: .Default,
                handler: { action in
                    Twitter.unblock(user.userID)
            }))
        } else {
            actionSheet.addAction(UIAlertAction(
                title: "Block",
                style: .Default,
                handler: { action in
                    Twitter.block(user.userID)
            }))
        }

        actionSheet.addAction(UIAlertAction(
            title: "Report",
            style: .Destructive,
            handler: { action in
                Twitter.reportSpam(user.userID)
        }))
    }

    private class func addURLAction(actionSheet: UIAlertController, user: TwitterUserFull) {
        for url in user.urls {
            if let openURL = NSURL(string: url.expandedURL) {
                actionSheet.addAction(UIAlertAction(
                    title: url.displayURL,
                    style: .Default,
                    handler: { action in
                        Safari.openURL(openURL)
                }))
            }
        }
    }
}
