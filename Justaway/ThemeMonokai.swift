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

    func statusBarStyle() -> UIStatusBarStyle { return .lightContent }
    func activityIndicatorStyle() -> UIActivityIndicatorViewStyle { return .white }
    func showMoreTweetIndicatorStyle() -> UIActivityIndicatorViewStyle { return .gray }
    func scrollViewIndicatorStyle() -> UIScrollViewIndicatorStyle { return .white }

    func mainBackgroundColor() -> UIColor { return ThemeColor.Monokai.black }
    func mainHighlightBackgroundColor() -> UIColor { return UIColor.darkGray }
    func titleTextColor() -> UIColor { return UIColor.white }
    func bodyTextColor() -> UIColor { return UIColor.white }
    func cellSeparatorColor() -> UIColor { return ThemeColor.Monokai.gray }

    func sideMenuBackgroundColor() -> UIColor { return ThemeColor.Monokai.gray }
    func switchTintColor() -> UIColor { return UIColor.white }

    func displayNameTextColor() -> UIColor { return ThemeColor.Monokai.yellow }
    func screenNameTextColor() -> UIColor { return ThemeColor.Monokai.red }
    func relativeDateTextColor() -> UIColor { return ThemeColor.Monokai.green }
    func absoluteDateTextColor() -> UIColor { return ThemeColor.Monokai.violet }
    func clientNameTextColor() -> UIColor { return ThemeColor.Monokai.blue }

    func menuBackgroundColor() -> UIColor { return ThemeColor.Monokai.gray }
    func menuTextColor() -> UIColor { return UIColor.white }
    func menuHighlightedTextColor() -> UIColor { return UIColor(red: 1, green: 1, blue: 1, alpha: 0.5) }
    func menuSelectedTextColor() -> UIColor { return ThemeColor.Monokai.blue }
    func menuDisabledTextColor() -> UIColor { return UIColor.gray }

    func showMoreTweetBackgroundColor() -> UIColor { return ThemeColor.Monokai.gray }
    func showMoreTweetLabelTextColor() -> UIColor { return UIColor.white }

    func buttonNormal() -> UIColor { return UIColor.lightGray }
    func retweetButtonSelected() -> UIColor { return ThemeColor.Monokai.green }
    func favoritesButtonSelected() -> UIColor { return ThemeColor.Monokai.red }
    func followButtonSelected() -> UIColor { return ThemeColor.Monokai.blue }
    func streamingConnected() -> UIColor { return ThemeColor.Monokai.green }
    func streamingError() -> UIColor { return ThemeColor.Monokai.red }

    func accountOptionEnabled() -> UIColor { return ThemeColor.Monokai.blue }

    func shadowOpacity() -> Float { return 0.5 }
}
