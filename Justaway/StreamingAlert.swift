//
//  StreamingAlert.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/17/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class StreamingAlert {
    class func show() {
        let actionSheet = UIAlertController()
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: { action in
                actionSheet.dismissViewControllerAnimated(true, completion: nil)
        }))
        if Twitter.connectionStatus == Twitter.ConnectionStatus.DISCONNECTED {
            actionSheet.addAction(UIAlertAction(
                title: "Connect streaming",
                style: .Default,
                handler: { action in
                    Twitter.startStreamingAndEnable()
            }))
        } else if Twitter.connectionStatus == Twitter.ConnectionStatus.CONNECTED {
            actionSheet.addAction(UIAlertAction(
                title: "Disconnect streaming",
                style: .Destructive,
                handler: { action in
                    Twitter.stopStreamingAndDisable()
            }))
        }
        AlertController.showViewController(actionSheet)
    }
}
