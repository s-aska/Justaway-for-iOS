//
//  ThemeDark.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/9/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class ThemeDark: Theme {
    func statusBarStyle() -> UIStatusBarStyle { return .LightContent }
    
    func mainBackgroundColor() -> UIColor { return UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1) }
    func mainHighlightBackgroundColor() -> UIColor { return UIColor.darkGrayColor() }
    func titleTextColor() -> UIColor { return UIColor.whiteColor() }
    func bodyTextColor() -> UIColor { return UIColor.whiteColor() }
    
    func displayNameTextColor() -> UIColor { return UIColor.whiteColor() }
    func screenNameTextColor() -> UIColor { return UIColor.lightGrayColor() }
    func relativeDateTextColor() -> UIColor { return UIColor.lightGrayColor() }
    func absoluteDateTextColor() -> UIColor { return UIColor.lightGrayColor() }
    func clientNameTextColor() -> UIColor { return UIColor.lightGrayColor() }
    
    func menuBackgroundColor() -> UIColor { return UIColor.darkGrayColor() }
    func menuTextColor() -> UIColor { return UIColor.whiteColor() }
    func menuHighlightTextColor() -> UIColor { return ThemeColor.Holo.blueLight }
    func menuDisabledTextColor() -> UIColor { return UIColor.grayColor() }
    
    func buttonNormal() -> UIColor { return UIColor.lightGrayColor() }
    func retweetButtonSelected() -> UIColor { return ThemeColor.Holo.greenLight }
    func favoritesButtonSelected() -> UIColor { return ThemeColor.Holo.greenLight }
    func streamingConnected() -> UIColor { return ThemeColor.Holo.greenLight }
    func streamingError() -> UIColor { return ThemeColor.Holo.redLight }
    
}
