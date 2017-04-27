//
//  MessageAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/30/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class MessageAlert {
    class func show(_ title: String, message: String? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        AlertController.showViewController(alert)
    }
}
