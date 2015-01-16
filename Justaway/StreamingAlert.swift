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
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: { action in
                actionSheet.dismissViewControllerAnimated(true, completion: nil)
        }))
        if Twitter.connectionStatus == Twitter.ConnectionStatus.DISCONNECTED {
            actionSheet.message = "Connect to the streaming"
            actionSheet.addAction(UIAlertAction(
                title: "Connect",
                style: .Default,
                handler: { action in
                    Twitter.startStreamingAndEnable()
            }))
        } else if Twitter.connectionStatus == Twitter.ConnectionStatus.CONNECTED {
            actionSheet.message = "Disconnect to the streaming"
            actionSheet.addAction(UIAlertAction(
                title: "Disconnect",
                style: .Destructive,
                handler: { action in
                    Twitter.stopStreamingAndDisable()
            }))
        }
        AlertController.showViewController(actionSheet)
    }
}
