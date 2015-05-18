//
//  Theme.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/8/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import KeyClip

protocol Theme {
    
    func name() -> String
    
    func statusBarStyle() -> UIStatusBarStyle
    func activityIndicatorStyle() -> UIActivityIndicatorViewStyle
    func scrollViewIndicatorStyle() -> UIScrollViewIndicatorStyle
    
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
        static let themes: [Theme] = [ThemeLight(), ThemeDark(), ThemeSolarizedLight(), ThemeSolarizedDark(), ThemeMonokai()]
        static var currentTheme: Theme = ThemeLight()
    }
    
    class var currentTheme: Theme { return Static.currentTheme }
    
    class func apply() {
        if let themeName = KeyClip.load("theme") as String? {
            for theme in Static.themes {
                if theme.name() == themeName {
                    apply(theme)
                    return
                }
            }
        }
        apply(currentTheme, refresh: false)
    }
    
    class func apply(theme: Theme, refresh: Bool = true) {
        
        Static.currentTheme = theme
        
        // for UIKit
        
        // Note: Adding "View controller-based status bar appearance" to info.plist and setting it to "NO"
        UIApplication.sharedApplication().statusBarStyle = theme.statusBarStyle()
        UITableViewCell.appearance().backgroundColor = theme.mainBackgroundColor()
        UITableView.appearance().backgroundColor = theme.mainBackgroundColor()
        UITableView.appearance().indicatorStyle = theme.scrollViewIndicatorStyle()
        UITextView.appearance().textColor = theme.bodyTextColor()
        UITextView.appearance().backgroundColor = theme.mainBackgroundColor()
        
        // for CustomView
        TextLable.appearance().textColor = theme.bodyTextColor()
        BackgroundScrollView.appearance().backgroundColor = theme.mainBackgroundColor()
        BackgroundScrollView.appearance().indicatorStyle = theme.scrollViewIndicatorStyle()
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
        StreamingButton.appearance().setTitleColor(theme.bodyTextColor(), forState: .Normal)
        StreamingButton.appearance().setTitleColor(theme.streamingConnected(), forState: .Selected)
        StreamingButton.appearance().setTitleColor(theme.streamingError(), forState: .Disabled)
        
        if refresh {
            CATransaction.begin()
            CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
            refreshAppearance(theme)
            CATransaction.commit()
            
            KeyClip.save("theme", string: theme.name())
        }
    }
    
    class func refreshAppearance(theme: Theme) {
        let windows = UIApplication.sharedApplication().windows as! [UIWindow]
        for window in windows {
            refreshWindow(window, theme: theme)
        }
        if let rootView = windows.first?.subviews.first as? UIView {
            rootView.backgroundColor = theme.mainBackgroundColor()
        }
        windows.first?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
    }
    
    class func refreshWindow(window: UIWindow, theme: Theme) {
        // NSLog("+ \(NSStringFromClass(window.dynamicType))")
        for subview in window.subviews as! [UIView] {
            refreshView(subview, theme: theme)
        }
    }
    
    class func refreshView(view: UIView, theme: Theme, indent: String = "  ") {
        // NSLog("\(indent)- \(NSStringFromClass(view.dynamicType))")
        for subview in view.subviews as! [UIView] {
            refreshView(subview, theme: theme, indent: indent + "  ")
            switch subview {
            case let v as BackgroundScrollView:
                v.indicatorStyle = theme.scrollViewIndicatorStyle()
                v.backgroundColor = theme.mainBackgroundColor()
            case let v as UITableView:
                v.indicatorStyle = theme.scrollViewIndicatorStyle()
                v.backgroundColor = theme.mainBackgroundColor()
            case let v as UITextView:
                v.textColor = theme.bodyTextColor()
                v.backgroundColor = theme.mainBackgroundColor()
            case let v as UITableViewCell:
                v.backgroundColor = theme.mainBackgroundColor()
            case let v as BackgroundView:
                v.backgroundColor = theme.mainBackgroundColor()
            case let v as MenuView:
                v.backgroundColor = theme.menuBackgroundColor()
            case let v as MenuButton:
                v.setTitleColor(theme.menuTextColor(), forState: .Normal)
            case let v as TextLable:
                v.textColor = theme.titleTextColor()
            case let v as DisplayNameLable:
                v.textColor = theme.displayNameTextColor()
            case let v as ScreenNameLable:
                v.textColor = theme.screenNameTextColor()
            case let v as ClientNameLable:
                v.textColor = theme.clientNameTextColor()
            case let v as RelativeDateLable:
                v.textColor = theme.relativeDateTextColor()
            case let v as AbsoluteDateLable:
                v.textColor = theme.absoluteDateTextColor()
            case let v as StatusLable:
                v.textColor = theme.bodyTextColor()
            case let v as ReplyButton:
                v.setTitleColor(theme.buttonNormal(), forState: .Normal)
                v.setTitleColor(theme.buttonNormal(), forState: .Selected)
            case let v as RetweetButton:
                v.setTitleColor(theme.buttonNormal(), forState: .Normal)
                v.setTitleColor(theme.retweetButtonSelected(), forState: .Selected)
            case let v as FavoritesButton:
                v.setTitleColor(theme.buttonNormal(), forState: .Normal)
                v.setTitleColor(theme.favoritesButtonSelected(), forState: .Selected)
            case let v as StreamingButton:
                v.setTitleColor(theme.bodyTextColor(), forState: .Normal)
                v.setTitleColor(theme.streamingConnected(), forState: .Selected)
                v.setTitleColor(theme.streamingError(), forState: .Disabled)
            case let v as CellSeparator:
                v.borderLayer?.backgroundColor = theme.menuBackgroundColor().CGColor
            case let v as UIActivityIndicatorView:
                v.activityIndicatorViewStyle = theme.activityIndicatorStyle()
            default:
                break
            }
        }
    }
    
    // viewWillAppear of various ViewController is executed.
    // very heavy.
    class func refreshAppearanceSuperSlow() {
        let windows = UIApplication.sharedApplication().windows as! [UIWindow]
        for window in windows {
            let subviews = window.subviews as! [UIView]
            for v in subviews {
                v.removeFromSuperview()
                window.addSubview(v)
            }
        }
    }
}
