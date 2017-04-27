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
        let timer: Timer

        init(timer: Timer) {
            self.timer = timer
        }
    }

    struct Static {
        fileprivate static var schedules = [String: Schedule]()
        fileprivate static let serial = DispatchQueue(label: "pw.aska.Scheduler", attributes: [])
    }

    class func regsiter(interval: TimeInterval, target: AnyObject, selector: Selector) {
        let key = "\(UInt(bitPattern: ObjectIdentifier(target))):\(selector)"
        Static.serial.sync {
            if Static.schedules[key]?.timer.isValid ?? false {
                return
            }
            let timer = Timer.scheduledTimer(timeInterval: interval, target: target, selector: selector, userInfo: nil, repeats: false)
            Static.schedules[key] = Schedule(timer: timer)
        }
    }
}
