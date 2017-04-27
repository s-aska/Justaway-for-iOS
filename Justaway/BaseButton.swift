//
//  BaseButton.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/8/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import Async

@IBDesignable class BaseButton: UIButton {

    var locked = false

    @IBInspectable var cornerRadius: CGFloat = 0
    @IBInspectable var borderColor: UIColor = UIColor.clear
    @IBInspectable var borderWidth: CGFloat = 0
    @IBInspectable var layerColor: UIColor = UIColor.clear

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

    override func draw(_ rect: CGRect) {
        if borderWidth > 0 {
            layer.cornerRadius = cornerRadius
            layer.borderColor = borderColor.cgColor
            layer.borderWidth = borderWidth
            layer.backgroundColor = layerColor.cgColor
        }
        super.draw(rect)
    }

    func setup() {
        self.isExclusiveTouch = true
    }

    func lock(_ interval: TimeInterval = 1) -> Bool {
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
