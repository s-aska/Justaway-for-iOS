//
//  AddAccountAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/30/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class AddAccountAlert {
    class func show(sender: UIView) {
        let actionSheet =  UIAlertController(title: "Add Account", message: "Choose via", preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "via iOS", style: .Default, handler: { action in
            Twitter.addACAccount(false)
        }))
        actionSheet.addAction(UIAlertAction(title: "via Justaway for iOS", style: .Default, handler: { action in
            Twitter.addOAuthAccount()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        
        // iPad
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds
        
        AlertController.showViewController(actionSheet)
    }
}
