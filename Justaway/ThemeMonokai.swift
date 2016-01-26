//
//  ThemeMonokai.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/15/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class ThemeMonokai: Theme {

    func name() -> String { return "Monokai" }

    func statusBarStyle() -> UIStatusBarStyle { return .LightContent }
    func activityIndicatorStyle() -> UIActivityIndicatorViewStyle { return .White }
    func scrollViewIndicatorStyle() -> UIScrollViewIndicatorStyle { return .White }

    func mainBackgroundColor() -> UIColor { return ThemeColor.Monokai.black }
    func mainHighlightBackgroundColor() -> UIColor { return UIColor.darkGrayColor() }
    func titleTextColor() -> UIColor { return UIColor.whiteColor() }
    func bodyTextColor() -> UIColor { return UIColor.whiteColor() }
    func cellSeparatorColor() -> UIColor { return UIColor.lightGrayColor() }

    func sideMenuBackgroundColor() -> UIColor { return ThemeColor.Monokai.gray }
    func switchTintColor() -> UIColor { return UIColor.whiteColor() }

    func displayNameTextColor() -> UIColor { return ThemeColor.Monokai.yellow }
    func screenNameTextColor() -> UIColor { return ThemeColor.Monokai.red }
    func relativeDateTextColor() -> UIColor { return ThemeColor.Monokai.green }
    func absoluteDateTextColor() -> UIColor { return ThemeColor.Monokai.violet }
    func clientNameTextColor() -> UIColor { return ThemeColor.Monokai.blue }

    func menuBackgroundColor() -> UIColor { return ThemeColor.Monokai.gray }
    func menuTextColor() -> UIColor { return UIColor.whiteColor() }
    func menuHighlightedTextColor() -> UIColor { return UIColor(red: 1, green: 1, blue: 1, alpha: 0.5) }
    func menuSelectedTextColor() -> UIColor { return ThemeColor.Monokai.blue }
    func menuDisabledTextColor() -> UIColor { return UIColor.grayColor() }

    func buttonNormal() -> UIColor { return UIColor.lightGrayColor() }
    func retweetButtonSelected() -> UIColor { return ThemeColor.Monokai.green }
    func favoritesButtonSelected() -> UIColor { return ThemeColor.Monokai.orange }
    func streamingConnected() -> UIColor { return ThemeColor.Monokai.green }
    func streamingError() -> UIColor { return ThemeColor.Monokai.red }

    func shadowOpacity() -> Float { return 0.5 }
}
