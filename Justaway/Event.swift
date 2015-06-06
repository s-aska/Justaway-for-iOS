//
//  Event.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/25/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import EventBox

class Event {
    class var name: String {
        return NSStringFromClass(self)
    }
    func post() {
        EventBox.post(NSStringFromClass(self.dynamicType), sender: self)
    }
}
