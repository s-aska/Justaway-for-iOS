//
//  AddAccountAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/30/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class AddAccountAlert {
    class func show() {
        var actionSheet =  UIAlertController(title: "Add Account", message: "Choose via", preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "via iOS", style: .Default, handler: { action in
            Twitter.addACAccount()
        }))
        actionSheet.addAction(UIAlertAction(title: "via Justaway for iOS", style: .Default, handler: { action in
            Twitter.addOAuthAccount()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        AlertController.showViewController(actionSheet)
    }
}
