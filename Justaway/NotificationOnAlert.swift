//
//  NotificationOnAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/1/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit

class NotificationOnAlert {
    class func show(sender: UIView) {
        let alert = UIAlertController(title: "Enable Notification?", message: "Additional authentication is required.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { action in
            SafariExURLHandler.open()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        AlertController.showViewController(alert)
    }
}
