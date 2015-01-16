//
//  RetweetAlertController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/17/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class RetweetAlertController {
    class func create(statusID: String) -> UIAlertController {
        let actionSheet = UIAlertController()
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: { action in
                actionSheet.dismissViewControllerAnimated(true, completion: nil)
        }))
        actionSheet.addAction(UIAlertAction(
            title: "Retweet",
            style: .Default,
            handler: { action in
                Twitter.createRetweet(statusID)
        }))
        actionSheet.addAction(UIAlertAction(
            title: "Quote Tweet URL",
            style: .Default,
            handler: { action in
                
        }))
        return actionSheet
    }
}
