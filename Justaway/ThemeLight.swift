//
//  ThemeLight.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/9/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class ThemeLight: Theme {

    func name() -> String { return "Light" }

    func statusBarStyle() -> UIStatusBarStyle { return .default }
    func activityIndicatorStyle() -> UIActivityIndicatorViewStyle { return .gray }
    func showMoreTweetIndicatorStyle() -> UIActivityIndicatorViewStyle { return .white }
    func scrollViewIndicatorStyle() -> UIScrollViewIndicatorStyle { return .black }

    func mainBackgroundColor() -> UIColor { return UIColor(red: 0.97, green: 0.97, blue: 0.97, alpha: 1) }
    func mainHighlightBackgroundColor() -> UIColor { return UIColor(red: 0.80, green: 0.80, blue: 0.80, alpha: 1) }
    func titleTextColor() -> UIColor { return UIColor.darkGray }
    func bodyTextColor() -> UIColor { return UIColor.darkGray }
    func cellSeparatorColor() -> UIColor { return UIColor(red: 0.80, green: 0.80, blue: 0.80, alpha: 1) }

    func sideMenuBackgroundColor() -> UIColor { return UIColor.white }
    func switchTintColor() -> UIColor { return UIColor.gray }

    func displayNameTextColor() -> UIColor { return UIColor.darkGray }
    func screenNameTextColor() -> UIColor { return UIColor.lightGray }
    func relativeDateTextColor() -> UIColor { return UIColor.lightGray }
    func absoluteDateTextColor() -> UIColor { return UIColor.lightGray }
    func clientNameTextColor() -> UIColor { return UIColor.lightGray }

    func menuBackgroundColor() -> UIColor { return UIColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 1) }
    func menuTextColor() -> UIColor { return UIColor.darkGray }
    func menuHighlightedTextColor() -> UIColor { return UIColor(red: 0.666, green: 0.666, blue: 0.666, alpha: 0.5) }
    func menuSelectedTextColor() -> UIColor { return ThemeColor.Holo.blueDark }
    func menuDisabledTextColor() -> UIColor { return UIColor.gray }

    func showMoreTweetBackgroundColor() -> UIColor { return UIColor(red: 0.80, green: 0.80, blue: 0.80, alpha: 1) }
    func showMoreTweetLabelTextColor() -> UIColor { return UIColor.darkGray }

    func buttonNormal() -> UIColor { return UIColor.lightGray }
    func retweetButtonSelected() -> UIColor { return ThemeColor.Holo.greenDark }
    func favoritesButtonSelected() -> UIColor { return ThemeColor.Holo.redDark }
    func followButtonSelected() -> UIColor { return ThemeColor.Holo.blueDark }
    func streamingConnected() -> UIColor { return ThemeColor.Holo.greenDark }
    func streamingError() -> UIColor { return ThemeColor.Holo.redDark }

    func accountOptionEnabled() -> UIColor { return ThemeColor.Holo.blueLight }

    func shadowOpacity() -> Float { return 0.1 }
}
