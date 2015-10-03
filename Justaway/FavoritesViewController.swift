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
            if let userID = self.userID {
                let key = "favorites:\(userID)"
                let statuses = self.adapter.statuses
                let dictionary = ["statuses": ( statuses.count > 100 ? Array(statuses[0 ..< 100]) : statuses ).map({ $0.dictionaryValue })]
                KeyClip.save(key, dictionary: dictionary)
                NSLog("favorites:\(userID) saveCache.")
            }
        }
    }
    
    override func loadCache(success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        if let userID = self.userID {
            let key = "favorites:\(userID)"
            Async.background {
                if let cache = KeyClip.load(key) as NSDictionary? {
                    if let statuses = cache["statuses"] as? [[String: AnyObject]] {
                        success(statuses: statuses.map({ TwitterStatus($0) }))
                        return
                    }
                }
                success(statuses: [TwitterStatus]())
            }
        } else {
            success(statuses: [])
        }
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
