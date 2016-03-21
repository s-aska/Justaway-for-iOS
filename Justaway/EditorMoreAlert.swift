//
//  EditorMoreAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 3/22/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit

class EditorMoreAlert {
    class func show(sender: UIView, text: String, callback: ((String) -> Void)) {
        let actionSheet =  UIAlertController(title: "Option", message: nil, preferredStyle: .ActionSheet)
        actionSheet.addAction(UIAlertAction(title: "Half width", style: .Default, handler: { action in
            let text = NSMutableString(string: text) as CFMutableString
            CFStringTransform(text, nil, kCFStringTransformFullwidthHalfwidth, false)
            callback(text as String)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))

        // iPad
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds

        AlertController.showViewController(actionSheet)
    }
}
