//
//  Scheduler.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/9/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

class Scheduler {
    struct Static {
        private static var asyncs = [String: Async]()
        private static var lasts = [String: NSTimeInterval]()
        private static let serial = dispatch_queue_create("pw.aska.Debouncer", DISPATCH_QUEUE_SERIAL)
    }
    
    class func regsiter(min min: NSTimeInterval, max: NSTimeInterval, target: AnyObject, selector: Selector) {
        dispatch_sync(Static.serial) {
            let key = "\(ObjectIdentifier(target).uintValue):\(selector)"
            if let _ = Static.asyncs.removeValueForKey(key) {
                return // http://www.openradar.me/22437691 dispatch_block_t re-audit causes GCD APIs to crashし
                // async.cancel()
            }
            let block: (() -> Void) = {
                Static.lasts[key] = NSDate().timeIntervalSince1970
                NSTimer.scheduledTimerWithTimeInterval(0, target: target, selector: selector, userInfo: nil, repeats: false)
            }
            let last = Static.lasts[key] ?? 0
            let now = NSDate().timeIntervalSince1970
            if (now - last) > max {
                block()
            } else {
                Static.asyncs[key] = Async.background(after: min, block: block)
            }
        }
    }
}
