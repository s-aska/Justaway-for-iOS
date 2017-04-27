import UIKit

class StreamingAlert {
    class func show(_ sender: UIView) {
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .cancel,
            handler: { action in
                actionSheet.dismiss(animated: true, completion: nil)
        }))
        actionSheet.message = "Streaming Menu"
        actionSheet.addAction(UIAlertAction(
            title: "Set to Auto Connect" + (Twitter.streamingMode == .AutoAlways ? " *" : ""),
            style: .default,
            handler: { action in
                Twitter.changeMode(.AutoAlways)
        }))
        actionSheet.addAction(UIAlertAction(
            title: "Set to Auto Connect on Wi-Fi" + (Twitter.streamingMode == .AutoOnWiFi ? " *" : ""),
            style: .default,
            handler: { action in
                Twitter.changeMode(.AutoOnWiFi)
        }))
        actionSheet.addAction(UIAlertAction(
            title: "Set to Manual Connect" + (Twitter.streamingMode == .Manual ? " *" : ""),
            style: .default,
            handler: { action in
                Twitter.changeMode(.Manual)
        }))
        if Twitter.connectionStatus == Twitter.ConnectionStatus.disconnected {
            actionSheet.addAction(UIAlertAction(
                title: "Connect once",
                style: .default,
                handler: { action in
                    Twitter.startStreamingIfDisconnected()
            }))
        } else if Twitter.connectionStatus == Twitter.ConnectionStatus.connected {
            actionSheet.addAction(UIAlertAction(
                title: "Disconnect",
                style: .destructive,
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
