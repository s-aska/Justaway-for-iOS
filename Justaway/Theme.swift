//
//  Theme.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/8/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class Theme {
    class func white() {
        FavoritesButton.appearance().setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
        FavoritesButton.appearance().setTitleColor(UIColor.orangeColor(), forState: .Selected)
    }
}
