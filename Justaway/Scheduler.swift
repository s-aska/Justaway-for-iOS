//
//  Scheduler.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/9/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

class Scheduler {
    struct Schedule {
        let timer: NSTimer
        
        init(timer: NSTimer) {
            self.timer = timer
        }
    }
    
    struct Static {
        private static var schedules = [String: Schedule]()
        private static let serial = dispatch_queue_create("pw.aska.Scheduler", DISPATCH_QUEUE_SERIAL)
    }
    
    class func regsiter(interval interval: NSTimeInterval, target: AnyObject, selector: Selector) {
        let key = "\(ObjectIdentifier(target).uintValue):\(selector)"
        dispatch_sync(Static.serial) {
            if Static.schedules[key]?.timer.valid ?? false {
                return
            }
            let timer = NSTimer.scheduledTimerWithTimeInterval(interval, target: target, selector: selector, userInfo: nil, repeats: false)
            Static.schedules[key] = Schedule(timer: timer)
        }
    }
}
