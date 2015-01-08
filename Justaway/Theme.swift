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
}

class ThemeController {
    
    class func apply() {
        apply(ThemeLight())
    }
    
    class func apply(theme: Theme) {
        
        MenuView.appearance().backgroundColor = theme.menuBackgroundColor()
        MenuButton.appearance().setTitleColor(theme.menuTextColor(), forState: .Normal)
        
        DisplayNameLable.appearance().textColor = theme.displayNameTextColor()
        ScreenNameLable.appearance().textColor = theme.screenNameTextColor()
        ClientNameLable.appearance().textColor = theme.clientNameTextColor()
        RelativeDateLable.appearance().textColor = theme.relativeDateTextColor()
        AbsoluteDateLable.appearance().textColor = theme.absoluteDateTextColor()
        
        ReplyButton.appearance().setTitleColor(theme.buttonNormal(), forState: .Normal)
        ReplyButton.appearance().setTitleColor(theme.buttonNormal(), forState: .Selected)
        RetweetButton.appearance().setTitleColor(theme.buttonNormal(), forState: .Normal)
        RetweetButton.appearance().setTitleColor(theme.retweetButtonSelected(), forState: .Selected)
        FavoritesButton.appearance().setTitleColor(theme.buttonNormal(), forState: .Normal)
        FavoritesButton.appearance().setTitleColor(theme.favoritesButtonSelected(), forState: .Selected)
        
    }
}
