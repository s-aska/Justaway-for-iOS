//
//  LocalNotification.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/4/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit

class LocalNotification {

    struct Static {
        private static let queue = NSOperationQueue.init().serial()
    }

    class func show(message: String) {
        let op = AsyncBlockOperation { (op) in
            ToastViewController.show(message, completion: {
                op.finish()
            })
        }
        Static.queue.addOperation(op)
    }
}
