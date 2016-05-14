//
//  TwitterRelationship.swift
//  Justaway
//
//  Created by Shinichiro Aska on 6/6/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import SwiftyJSON

struct TwitterRelationship {
    let canDM: Bool
    let blocking: Bool
    let muting: Bool
    let markedSpam: Bool
    let following: Bool
    let followedBy: Bool
    let wantRetweets: Bool
    let allReplies: Bool
    let notificationsEnabled: Bool

    init(_ json: JSON) {
        self.canDM = json["can_dm"].boolValue
        self.blocking = json["blocking"].boolValue
        self.muting = json["muting"].boolValue
        self.markedSpam = json["marked_spam"].boolValue
        self.following = json["following"].boolValue
        self.followedBy = json["followed_by"].boolValue
        self.wantRetweets = json["want_retweets"].boolValue
        self.allReplies = json["all_replies"].boolValue
        self.notificationsEnabled = json["notifications_enabled"].boolValue
    }

    init(following: Bool, followedBy: Bool, blocking: Bool, muting: Bool, wantRetweets: Bool) {
        self.following = following
        self.followedBy = followedBy
        self.blocking = blocking
        self.muting = muting
        self.wantRetweets = wantRetweets
        self.canDM = following && followedBy
        self.markedSpam = false
        self.allReplies = false
        self.notificationsEnabled = false
    }
}
