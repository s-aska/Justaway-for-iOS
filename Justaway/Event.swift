//
//  Event.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/25/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import EventBox

class Event {
    class var name: String {
        NSLog("name: \(NSStringFromClass(self))")
        return NSStringFromClass(self)
    }
    func post() {
        NSLog("post: \(NSStringFromClass(self.dynamicType))")
        EventBox.post(NSStringFromClass(self.dynamicType), sender: self)
    }
}

class EditorEvent: Event {
    let text: String
    let range: NSRange?
    let inReplyToStatusId: String?
    init(text: String, range: NSRange?, inReplyToStatusId: String?) {
        self.text = text
        self.range = range
        self.inReplyToStatusId = inReplyToStatusId
    }
}

class ImageViewEvent: Event {
    let media: [TwitterMedia]
    let page: Int
    init(media: [TwitterMedia], page: Int) {
        self.media = media
        self.page = page
    }
}
