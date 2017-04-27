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

    func statusBarStyle() -> UIStatusBarStyle { return .lightContent }
    func statusBarBackgroundColor() -> UIColor { return UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 0.9) }
    func activityIndicatorStyle() -> UIActivityIndicatorViewStyle { return .white }
    func showMoreTweetIndicatorStyle() -> UIActivityIndicatorViewStyle { return .gray }
    func scrollViewIndicatorStyle() -> UIScrollViewIndicatorStyle { return .white }

    func mainBackgroundColor() -> UIColor { return UIColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1) }
    func mainHighlightBackgroundColor() -> UIColor { return UIColor.darkGray }
    func titleTextColor() -> UIColor { return UIColor.white }
    func bodyTextColor() -> UIColor { return UIColor.white }
    func cellSeparatorColor() -> UIColor { return UIColor.lightGray }

    func sideMenuBackgroundColor() -> UIColor { return UIColor.darkGray }
    func switchTintColor() -> UIColor { return UIColor.white }

    func displayNameTextColor() -> UIColor { return UIColor.white }
    func screenNameTextColor() -> UIColor { return UIColor.lightGray }
    func relativeDateTextColor() -> UIColor { return UIColor.lightGray }
    func absoluteDateTextColor() -> UIColor { return UIColor.lightGray }
    func clientNameTextColor() -> UIColor { return UIColor.lightGray }

    func menuBackgroundColor() -> UIColor { return UIColor.darkGray }
    func menuTextColor() -> UIColor { return UIColor.white }
    func menuHighlightedTextColor() -> UIColor { return UIColor(red: 1, green: 1, blue: 1, alpha: 0.5) }
    func menuSelectedTextColor() -> UIColor { return ThemeColor.Holo.blueLight }
    func menuDisabledTextColor() -> UIColor { return UIColor.gray }

    func showMoreTweetBackgroundColor() -> UIColor { return UIColor.lightGray }
    func showMoreTweetLabelTextColor() -> UIColor { return UIColor.black }

    func buttonNormal() -> UIColor { return UIColor.lightGray }
    func retweetButtonSelected() -> UIColor { return ThemeColor.Holo.greenLight }
    func favoritesButtonSelected() -> UIColor { return ThemeColor.Holo.redLight }
    func followButtonSelected() -> UIColor { return ThemeColor.Holo.blueLight }
    func streamingConnected() -> UIColor { return ThemeColor.Holo.greenLight }
    func streamingError() -> UIColor { return ThemeColor.Holo.redLight }

    func accountOptionEnabled() -> UIColor { return ThemeColor.Holo.blueDark }

    func shadowOpacity() -> Float { return 0.5 }
}
