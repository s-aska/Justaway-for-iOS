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
import Async

class FavoritesTableViewController: StatusTableViewController {

    var userID: String?

    override func saveCache() {
        if self.adapter.rows.count > 0 {
            if let userID = self.userID {
                let key = "favorites:\(userID)"
                let statuses = self.adapter.statuses
                let dictionary = ["statuses": ( statuses.count > 100 ? Array(statuses[0 ..< 100]) : statuses ).map({ $0.dictionaryValue })]
                _ = KeyClip.save(key, dictionary: dictionary as NSDictionary)
                NSLog("favorites:\(userID) saveCache.")
            }
        }
    }

    override func loadCache(_ success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        if let userID = self.userID {
            let key = "favorites:\(userID)"
            Async.background {
                if let cache = KeyClip.load(key) as NSDictionary? {
                    if let statuses = cache["statuses"] as? [[String: AnyObject]] {
                        success(statuses.map({ TwitterStatus($0) }))
                        return
                    }
                }
                success([TwitterStatus]())

                Async.background(after: 0.5, { () -> Void in
                    self.loadData(nil)
                })
            }
        } else {
            success([])
        }
    }

    override func loadData(_ maxID: String?, success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        if let userID = self.userID {
            Twitter.getFavorites(userID, maxID: maxID, success: success, failure: failure)
        } else {
            success([])
        }
    }

    override func loadData(sinceID: String?, maxID: String?, success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        if let userID = self.userID {
            Twitter.getFavorites(userID, maxID: maxID, sinceID: sinceID, success: success, failure: failure)
        } else {
            success([])
        }
    }

    override func accept(_ status: TwitterStatus) -> Bool {
        if let userID = self.userID {
            if let actionedByUserID = status.actionedBy?.userID {
                if actionedByUserID == userID && status.type == .favorite {
                    return true
                }
            }
        }
        return false
    }

    override func configureEvent() {
        super.configureEvent()
        EventBox.onMainThread(self, name: Twitter.Event.DestroyFavorites.Name(), sender: nil) { n in
            if let statusID = n.object as? String {
                self.eraseData(statusID, handler: {})
            }
        }
    }
}
