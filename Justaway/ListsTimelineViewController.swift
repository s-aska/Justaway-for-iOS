import UIKit
import KeyClip
import EventBox
import Async
import SwiftyJSON

class ListsTimelineTableViewController: StatusTableViewController {

    var list: TwitterList?
    var memberIDs: NSCache<AnyObject, AnyObject>?

    override func viewDidLoad() {
        super.viewDidLoad()
        adapter.scrollEnd(tableView) // contentInset call scrollViewDidScroll, but call scrollEnd
    }

    override func configureEvent() {
        super.configureEvent()
        EventBox.onBackgroundThread(self, name: Twitter.Event.ListMemberAdded.Name()) { (n) in
            guard let object = n.object as? [String: String] else {
                return
            }
            guard let targetUserID = object["targetUserID"], let targetListID = object["targetListID"] else {
                return
            }
            if let list = self.list, list.id == targetListID {
                self.memberIDs?.setObject(true as AnyObject, forKey: targetUserID as AnyObject)
                NSLog("ListsTimelineTableViewController member added:\(targetUserID)")
            }
        }
        EventBox.onBackgroundThread(self, name: Twitter.Event.ListMemberRemoved.Name()) { (n) in
            guard let object = n.object as? [String: String] else {
                return
            }
            guard let targetUserID = object["targetUserID"], let targetListID = object["targetListID"] else {
                return
            }
            if let list = self.list, list.id == targetListID {
                self.memberIDs?.removeObject(forKey: targetUserID as AnyObject)
                NSLog("ListsTimelineTableViewController member removed:\(targetUserID)")
            }
        }
    }

    override func saveCache() {
        if self.adapter.rows.count > 0 {
            if let list = self.list {
                let key = "lists:\(list.id)"
                let statuses = self.adapter.statuses
                let dictionary = ["statuses": ( statuses.count > 100 ? Array(statuses[0 ..< 100]) : statuses ).map({ $0.dictionaryValue })]
                _ = KeyClip.save(key, dictionary: dictionary as NSDictionary)
                NSLog("\(key) saveCache.")
            }
        }
    }

    override func loadCache(_ success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        if let list = self.list {
            let key = "lists:\(list.id)"
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
            if memberIDs == nil {
                memberIDs = NSCache.init()
                memberIDs?.countLimit = 5000
                Async.background {
                    let key = "lists:\(list.id):members"
                    var createdAt: NSNumber = 0
                    if let cache = KeyClip.load(key) as NSDictionary?, let ids = cache["ids"] as? [String] {
                        for id in ids {
                            self.memberIDs?.setObject(true as AnyObject, forKey: id as AnyObject)
                        }
                        createdAt = (cache["createdAt"] as? NSNumber) ?? 0
                        NSLog("ListsTimelineTableViewController load cache createdAt:\(createdAt)")
                    }
                    let delta = Date(timeIntervalSinceNow: 0).timeIntervalSince1970 - createdAt.doubleValue
                    NSLog("ListsTimelineTableViewController cache delta:\(delta)")
                    if delta > 60 {
                        let account = AccountSettingsStore.get()?.account()
                        let success = { (json: JSON) -> Void in
                            guard let users = json["users"].array else {
                                return
                            }
                            let ids = users.flatMap({ $0["id_str"].string }).filter({ !$0.isEmpty })
                            for id in ids {
                                self.memberIDs?.setObject(true as AnyObject, forKey: id as AnyObject)
                            }
                            _ = KeyClip.save(key, dictionary: ["ids": ids, "createdAt": Int(Date(timeIntervalSinceNow: 0).timeIntervalSince1970)])
                            NSLog("ListsTimelineTableViewController save cache createdAt:\(Int(Date(timeIntervalSinceNow: 0).timeIntervalSince1970))")
                        }
                        let parameters = ["list_id": list.id, "count": "5000", "include_entities": "false", "skip_status": "true"]
                        account?.client
                            .get("https://api.twitter.com/1.1/lists/members.json", parameters: parameters)
                            .responseJSON(success)
                    }
                }
            }
        } else {
            success([])
        }
    }

    override func loadData(_ maxID: String?, success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        guard let list = list else {
            return
        }
        Twitter.getListsStatuses(list.id, maxID: maxID, success: success, failure: failure)
    }

    override func loadData(sinceID: String?, maxID: String?, success: @escaping ((_ statuses: [TwitterStatus]) -> Void), failure: @escaping ((_ error: NSError) -> Void)) {
        guard let list = list else {
            return
        }
        Twitter.getListsStatuses(list.id, maxID: maxID, sinceID: sinceID, success: success, failure: failure)
    }

    override func accept(_ status: TwitterStatus) -> Bool {
        if status.type == .normal && (memberIDs?.object(forKey: status.user.userID as AnyObject) != nil) {
            return true
        }
        return false
    }
}
