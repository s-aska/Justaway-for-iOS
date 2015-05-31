//
//  MessageAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/30/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class MessageAlert {
    class func show(title: String, message: String? = nil) {
        var alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: nil))
        AlertController.showViewController(alert)
    }
}
