//
//  Theme.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/8/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit

protocol Theme {
    
    func statusBarStyle() -> UIStatusBarStyle
    
    func mainBackgroundColor() -> UIColor
    func mainHighlightBackgroundColor() -> UIColor
    func titleTextColor() -> UIColor
    func bodyTextColor() -> UIColor
    
    func displayNameTextColor() -> UIColor
    func screenNameTextColor() -> UIColor
    func relativeDateTextColor() -> UIColor
    func absoluteDateTextColor() -> UIColor
    func clientNameTextColor() -> UIColor
    
    func menuBackgroundColor() -> UIColor
    func menuTextColor() -> UIColor
    func menuHighlightTextColor() -> UIColor
    func menuDisabledTextColor() -> UIColor
    
    func buttonNormal() -> UIColor
    func retweetButtonSelected() -> UIColor
    func favoritesButtonSelected() -> UIColor
    
    func streamingConnected() -> UIColor
    func streamingError() -> UIColor
}

class ThemeController {
    
    struct Static {
        static var currentTheme: Theme = ThemeDark()
    }
    
    class var currentTheme: Theme { return Static.currentTheme }
    
    class func apply() {
        apply(Static.currentTheme)
    }
    
    class func apply(theme: Theme) {
        
        // for UIKit
        
        // Note: Adding "View controller-based status bar appearance" to info.plist and setting it to "NO"
        UIApplication.sharedApplication().statusBarStyle = theme.statusBarStyle()
        UITableViewCell.appearance().backgroundColor = theme.mainBackgroundColor()
        UITableView.appearance().backgroundColor = theme.mainBackgroundColor()
        
        // for CustomView
        TextLable.appearance().textColor = theme.bodyTextColor()
        BackgroundView.appearance().backgroundColor = theme.mainBackgroundColor()
        MenuView.appearance().backgroundColor = theme.menuBackgroundColor()
        MenuButton.appearance().setTitleColor(theme.menuTextColor(), forState: .Normal)
        
        // for TwitterStatus
        DisplayNameLable.appearance().textColor = theme.displayNameTextColor()
        ScreenNameLable.appearance().textColor = theme.screenNameTextColor()
        ClientNameLable.appearance().textColor = theme.clientNameTextColor()
        RelativeDateLable.appearance().textColor = theme.relativeDateTextColor()
        AbsoluteDateLable.appearance().textColor = theme.absoluteDateTextColor()
        StatusLable.appearance().textColor = theme.bodyTextColor()
        
        ReplyButton.appearance().setTitleColor(theme.buttonNormal(), forState: .Normal)
        ReplyButton.appearance().setTitleColor(theme.buttonNormal(), forState: .Selected)
        RetweetButton.appearance().setTitleColor(theme.buttonNormal(), forState: .Normal)
        RetweetButton.appearance().setTitleColor(theme.retweetButtonSelected(), forState: .Selected)
        FavoritesButton.appearance().setTitleColor(theme.buttonNormal(), forState: .Normal)
        FavoritesButton.appearance().setTitleColor(theme.favoritesButtonSelected(), forState: .Selected)
        
        // Note: viewWillAppear of various ViewController is executed. :/
        let windows = UIApplication.sharedApplication().windows as [UIWindow]
        for window in windows {
            let subviews = window.subviews as [UIView]
            for v in subviews {
                v.removeFromSuperview()
                window.addSubview(v)
            }
        }
    }
}
