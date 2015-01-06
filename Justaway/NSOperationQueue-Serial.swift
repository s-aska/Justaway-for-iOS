//
//  NSOperationQueue-Serial.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/7/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

extension NSOperationQueue {
    func serial() -> NSOperationQueue {
        self.maxConcurrentOperationCount = 1
        return self
    }
}
