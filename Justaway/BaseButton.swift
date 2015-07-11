//
//  BaseButton.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/8/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class BaseButton: UIButton {
    
    var locked = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setup()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setup() {
        self.exclusiveTouch = true
    }
    
    func lock(interval: NSTimeInterval = 1) -> Bool {
        if !locked {
            locked = true
            Async.background(after: interval) {
                self.locked = false
            }
            return true
        }
        return false
    }
}
