//
//  Extensions.swift
//  Justaway
//
//  Created by Shinichiro Aska on 4/1/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import Foundation

extension String {
    var longLongValue: Int64 {
        return (self as NSString).longLongValue
    }
}

extension Int64 {
    var stringValue: String {
        return String(self)
    }
}

extension OperationQueue {
    func serial() -> OperationQueue {
        self.maxConcurrentOperationCount = 1
        return self
    }
}
