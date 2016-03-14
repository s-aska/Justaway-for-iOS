//
//  ErrorAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/17/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class ErrorAlert {
    class func show(title: String, message: String? = nil) {
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        actionSheet.addAction(UIAlertAction(
            title: "Close",
            style: .Cancel,
            handler: { action in
                actionSheet.dismissViewControllerAnimated(true, completion: nil)
        }))
        AlertController.showViewController(actionSheet)
    }

    class func show(error: NSError) {
        let title = error.localizedFailureReason ?? error.localizedDescription
        let message = error.localizedRecoverySuggestion
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        actionSheet.addAction(UIAlertAction(
            title: "Close",
            style: .Cancel,
            handler: { action in
                actionSheet.dismissViewControllerAnimated(true, completion: nil)
        }))
        AlertController.showViewController(actionSheet)
    }
}
