//
//  ThemeSolarizedLight.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/15/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

class ThemeSolarizedLight: Theme {

    func name() -> String { return "SolarizedLight" }

    func statusBarStyle() -> UIStatusBarStyle { return .Default }
    func activityIndicatorStyle() -> UIActivityIndicatorViewStyle { return .Gray }
    func scrollViewIndicatorStyle() -> UIScrollViewIndicatorStyle { return .Black }

    func mainBackgroundColor() -> UIColor { return ThemeColor.Solarized.baes3 }
    func mainHighlightBackgroundColor() -> UIColor { return ThemeColor.Solarized.baes2 }
    func titleTextColor() -> UIColor { return ThemeColor.Solarized.baes01 }
    func bodyTextColor() -> UIColor { return ThemeColor.Solarized.baes01 }
    func cellSeparatorColor() -> UIColor { return ThemeColor.Solarized.baes01 }

    func sideMenuBackgroundColor() -> UIColor { return ThemeColor.Solarized.baes3 }
    func switchTintColor() -> UIColor { return ThemeColor.Solarized.baes01 }

    func displayNameTextColor() -> UIColor { return ThemeColor.Solarized.yellow }
    func screenNameTextColor() -> UIColor { return ThemeColor.Solarized.red }
    func relativeDateTextColor() -> UIColor { return ThemeColor.Solarized.magenta }
    func absoluteDateTextColor() -> UIColor { return ThemeColor.Solarized.blue }
    func clientNameTextColor() -> UIColor { return ThemeColor.Solarized.green }

    func menuBackgroundColor() -> UIColor { return ThemeColor.Solarized.baes2 }
    func menuTextColor() -> UIColor { return ThemeColor.Solarized.baes01 }
    func menuHighlightedTextColor() -> UIColor { return UIColor(red: 0.35, green: 0.43, blue: 0.46, alpha: 0.5) }
    func menuSelectedTextColor() -> UIColor { return ThemeColor.Solarized.blue }
    func menuDisabledTextColor() -> UIColor { return ThemeColor.Solarized.baes1 }

    func buttonNormal() -> UIColor { return ThemeColor.Solarized.baes1 }
    func retweetButtonSelected() -> UIColor { return ThemeColor.Solarized.cyan }
    func favoritesButtonSelected() -> UIColor { return ThemeColor.Solarized.red }
    func streamingConnected() -> UIColor { return ThemeColor.Solarized.cyan }
    func streamingError() -> UIColor { return ThemeColor.Solarized.red }

    func shadowOpacity() -> Float { return 0.1 }
}
