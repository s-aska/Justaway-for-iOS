//
//  FavoritesViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/5/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import KeyClip
import EventBox

class FavoritesTableViewController: StatusTableViewController {
    
    var userID: String?
    
    override func saveCache() {
        if self.adapter.rows.count > 0 {
            // let dictionary = ["statuses": ( self.rows.count > 100 ? Array(self.rows[0 ..< 100]) : self.rows ).map({ $0.status.dictionaryValue })]
            // KeyClip.save("homeTimeline", dictionary: dictionary)
            // NSLog("homeTimeline saveCache.")
        }
    }
    
    override func loadCache(success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        success(statuses: [])
        // Twitter.getHomeTimelineCache(success, failure: failure)
    }
    
    override func loadData(maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        if let userID = self.userID {
            Twitter.getFavorites(userID, maxID: maxID, success: success, failure: failure)
        } else {
            success(statuses: [])
        }
    }
    
    override func loadData(sinceID sinceID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        if let userID = self.userID {
            Twitter.getFavorites(userID, sinceID: sinceID, success: success, failure: failure)
        } else {
            success(statuses: [])
        }
    }
    
    override func accept(status: TwitterStatus) -> Bool {
        if let userID = self.userID {
            if let actionedByUserID = status.actionedBy?.userID {
                if actionedByUserID == userID && status.type == .Favorite {
                    return true
                }
            }
        }
        return false
    }
    
    override func configureEvent() {
        super.configureEvent()
        EventBox.onMainThread(self, name: Twitter.Event.DestroyFavorites.rawValue, sender: nil) { n in
            let statusID = n.object as! String
            self.eraseData(statusID, handler: {})
        }
    }
}
