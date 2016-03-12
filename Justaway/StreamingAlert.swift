import UIKit

class StreamingAlert {
    class func show(sender: UIView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .Alert)
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: { action in
                actionSheet.dismissViewControllerAnimated(true, completion: nil)
        }))
        actionSheet.message = "Streaming Menu"
        actionSheet.addAction(UIAlertAction(
            title: "Set to Auto Connect" + (Twitter.streamingMode == .AutoAlways ? " *" : ""),
            style: .Default,
            handler: { action in
                Twitter.changeMode(.AutoAlways)
        }))
        actionSheet.addAction(UIAlertAction(
            title: "Set to Auto Connect on Wi-Fi" + (Twitter.streamingMode == .AutoOnWiFi ? " *" : ""),
            style: .Default,
            handler: { action in
                Twitter.changeMode(.AutoOnWiFi)
        }))
        actionSheet.addAction(UIAlertAction(
            title: "Set to Manual Connect" + (Twitter.streamingMode == .Manual ? " *" : ""),
            style: .Default,
            handler: { action in
                Twitter.changeMode(.Manual)
        }))
        if Twitter.connectionStatus == Twitter.ConnectionStatus.DISCONNECTED {
            actionSheet.addAction(UIAlertAction(
                title: "Connect once",
                style: .Default,
                handler: { action in
                    Twitter.startStreamingIfDisconnected()
            }))
        } else if Twitter.connectionStatus == Twitter.ConnectionStatus.CONNECTED {
            actionSheet.addAction(UIAlertAction(
                title: "Disconnect",
                style: .Destructive,
                handler: { action in
                    Twitter.stopStreamingIFConnected()
            }))
        }

        // iPad
        actionSheet.popoverPresentationController?.sourceView = sender
        actionSheet.popoverPresentationController?.sourceRect = sender.bounds

        AlertController.showViewController(actionSheet)
    }
}
