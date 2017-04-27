//
//  AlertController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/17/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import Async

class AlertController {
    class func showViewController(_ alert: UIAlertController) {
        if let vc = ViewTools.frontViewController() {
            // Calling presentViewController:animated:completion: from within tableView:didSelectRowAtIndexPath: is very slow
            // http://stackoverflow.com/questions/20320591/uitableview-and-presentviewcontroller-takes-2-clicks-to-display
            Async.main {
                vc.present(alert, animated: true, completion: nil)
            }
        }
    }
}
