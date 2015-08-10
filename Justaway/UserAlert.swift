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
            
            actionSheet.addAction(UIAlertAction(
                title: "Reply",
                style: .Default,
                handler: { action in
                    let prefix = "@\(user.screenName) "
                    let range = NSMakeRange(prefix.characters.count, 0)
                    EditorViewController.show(prefix, range: range)
            }))
            
            if relationship.followedBy {
                actionSheet.addAction(UIAlertAction(
                    title: "Direct Message",
                    style: .Default,
                    handler: { action in
                        let prefix = "D \(user.screenName) "
                        let range = NSMakeRange(prefix.characters.count, 0)
                        EditorViewController.show(prefix, range: range)
                }))
            }
            
            // Follow
            
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
            
            // Notifications
            
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
            
            // Retweets
            
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
            
            // Add/remove from lists
            
            
            
            // Mute
            
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
            
            // Block
            
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
            
            // Report
            
            actionSheet.addAction(UIAlertAction(
                title: "Report",
                style: .Destructive,
                handler: { action in
                    Twitter.reportSpam(user.userID)
            }))
        }
        
        // URL
        
        for url in user.urls {
            if let openURL = NSURL(string: url.expandedURL) {
                actionSheet.addAction(UIAlertAction(
                    title: url.displayURL,
                    style: .Default,
                    handler: { action in
                        UIApplication.sharedApplication().openURL(openURL)
                }))
            }
        }
        
        // iPad
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        
        AlertController.showViewController(actionSheet)
    }
}


