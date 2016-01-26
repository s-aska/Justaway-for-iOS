//
//  ThemeDark.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/9/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class ThemeDark: Theme {

    func name() -> String { return "Dark" }

    func statusBarStyle() -> UIStatusBarStyle { return .LightContent }
    func statusBarBackgroundColor() -> UIColor { return UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 0.9) }
    func activityIndicatorStyle() -> UIActivityIndicatorViewStyle { return .White }
    func scrollViewIndicatorStyle() -> UIScrollViewIndicatorStyle { return .White }

    func mainBackgroundColor() -> UIColor { return UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1) }
    func mainHighlightBackgroundColor() -> UIColor { return UIColor.darkGrayColor() }
    func titleTextColor() -> UIColor { return UIColor.whiteColor() }
    func bodyTextColor() -> UIColor { return UIColor.whiteColor() }
    func cellSeparatorColor() -> UIColor { return UIColor.lightGrayColor() }

    func sideMenuBackgroundColor() -> UIColor { return UIColor.darkGrayColor() }
    func switchTintColor() -> UIColor { return UIColor.whiteColor() }

    func displayNameTextColor() -> UIColor { return UIColor.whiteColor() }
    func screenNameTextColor() -> UIColor { return UIColor.lightGrayColor() }
    func relativeDateTextColor() -> UIColor { return UIColor.lightGrayColor() }
    func absoluteDateTextColor() -> UIColor { return UIColor.lightGrayColor() }
    func clientNameTextColor() -> UIColor { return UIColor.lightGrayColor() }

    func menuBackgroundColor() -> UIColor { return UIColor.darkGrayColor() }
    func menuTextColor() -> UIColor { return UIColor.whiteColor() }
    func menuHighlightedTextColor() -> UIColor { return UIColor(red: 1, green: 1, blue: 1, alpha: 0.5) }
    func menuSelectedTextColor() -> UIColor { return ThemeColor.Holo.blueLight }
    func menuDisabledTextColor() -> UIColor { return UIColor.grayColor() }

    func buttonNormal() -> UIColor { return UIColor.lightGrayColor() }
    func retweetButtonSelected() -> UIColor { return ThemeColor.Holo.greenLight }
    func favoritesButtonSelected() -> UIColor { return ThemeColor.Holo.orangeLight }
    func streamingConnected() -> UIColor { return ThemeColor.Holo.greenLight }
    func streamingError() -> UIColor { return ThemeColor.Holo.redLight }

    func shadowOpacity() -> Float { return 0.5 }
}
