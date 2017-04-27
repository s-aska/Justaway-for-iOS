//
//  AddAccountAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/30/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class AddAccountAlert {
    class func show(_ sender: UIView) {
        let actionSheet =  UIAlertController(title: "Add Account", message: "Choose via", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "via iOS ( from iOS Settings )", style: .default, handler: { action in
            Twitter.addACAccount(false)
        }))
        actionSheet.addAction(UIAlertAction(title: "via Justaway for iOS", style: .default, handler: { action in
            Twitter.addOAuthAccount()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        // iPad
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds

        AlertController.showViewController(actionSheet)
    }
}
