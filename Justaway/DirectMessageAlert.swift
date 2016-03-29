//
//  DirectMessageAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/29/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit

class DirectMessageAlert {
    class func show(account: Account, message: TwitterMessage) {
        let actionSheet = UIAlertController()
        actionSheet.message = message.text
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: { action in
        }))
        actionSheet.addAction(UIAlertAction(
            title: "Delete Message",
            style: .Destructive,
            handler: { action in
                Twitter.destroyMessage(account, messageID: message.id)
        }))
        AlertController.showViewController(actionSheet)
    }
}
