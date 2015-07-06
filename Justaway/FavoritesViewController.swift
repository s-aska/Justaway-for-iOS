//
//  FavoritesViewController.swift
//  Justaway
//
//  Created by Shinichiro Aska on 7/5/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import Foundation
import KeyClip

class FavoritesTableViewController: StatusTableViewController {
    
    var userID: String?
    
    override func saveCache() {
        if self.rows.count > 0 {
            // let dictionary = ["statuses": ( self.rows.count > 100 ? Array(self.rows[0 ..< 100]) : self.rows ).map({ $0.status.dictionaryValue })]
            // KeyClip.save("homeTimeline", dictionary: dictionary)
            // NSLog("homeTimeline saveCache.")
        }
    }
    
    override func loadCache(success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        // Twitter.getHomeTimelineCache(success, failure: failure)
    }
    
    override func loadData(id: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        if let userID = self.userID {
            Twitter.getFavorites(userID, maxID: nil, success: success, failure: failure)
        }
    }
    
    override func accept(status: TwitterStatus) -> Bool {
        return false
    }
}
