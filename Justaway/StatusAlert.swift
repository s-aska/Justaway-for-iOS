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
    class func show(status: TwitterStatus) {
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
                
                // Reply
                
                actionSheet.addAction(UIAlertAction(
                    title: "Reply",
                    style: .Default,
                    handler: { action in
                        Twitter.reply(status)
                }))
                
                // Favorite and Retweet
                
                if !isFavorite && retweetedStatusID == nil {
                    actionSheet.addAction(UIAlertAction(
                        title: "Favorite and Retweet",
                        style: .Default,
                        handler: { action in
                            Twitter.createFavorite(statusID)
                            Twitter.createRetweet(statusID)
                    }))
                }
                
                if isFavorite {
                    actionSheet.addAction(UIAlertAction(
                        title: "Unfavorite",
                        style: .Destructive,
                        handler: { action in
                            Twitter.destroyFavorite(statusID)
                    }))
                } else {
                    actionSheet.addAction(UIAlertAction(
                        title: "Favorite",
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
                    title: "Quote Tweet URL",
                    style: .Default,
                    handler: { action in
                        Twitter.quoteURL(status)
                }))
                
                // Share
                
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
                
                // URL
                
                for url in status.urls {
                    if let expandedURL = NSURL(string: url.expandedURL) {
                        actionSheet.addAction(UIAlertAction(
                            title: url.displayURL,
                            style: .Default,
                            handler: { action in
                                GoogleChrome.openURL(expandedURL)
                                return
                        }))
                    }
                }
                
                if let viaURL = status.via.URL {
                    actionSheet.addAction(UIAlertAction(
                        title: "via " + status.via.name,
                        style: .Default,
                        handler: { action in
                            UIApplication.sharedApplication().openURL(viaURL)
                            return
                    }))
                }
                
                AlertController.showViewController(actionSheet)
            }
        }
    }
}

