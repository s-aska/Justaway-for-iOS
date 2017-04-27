//
//  Constants.swift
//  Justaway
//
//  Created by Shinichiro Aska on 5/26/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation

// Device
let eventStatusBarTouched = Notification.Name.init(rawValue: "EventStatusBarTouched")

// Account Settings
let eventAccountChanged = Notification.Name.init(rawValue: "EventAccountChanged")
let eventTabChanged = Notification.Name.init(rawValue: "EventTabChanged")

// FontSize Settings
let eventFontSizePreview = Notification.Name.init(rawValue: "EventFontSizePreview")
let eventFontSizeApplied = Notification.Name.init(rawValue: "EventFontSizeApplied")
let eventChangeStreamingMode = Notification.Name.init(rawValue: "ChangeStreamingMode")
let eventSearchKeywordDeleted = Notification.Name.init(rawValue: "SearchKeywordDeleted")
