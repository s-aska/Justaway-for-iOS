import UIKit
import KeyClip
import EventBox
import Async

class ListsTimelineTableViewController: StatusTableViewController {

    var list: TwitterList?

    override func viewDidLoad() {
        super.viewDidLoad()
        adapter.scrollEnd(tableView) // contentInset call scrollViewDidScroll, but call scrollEnd
    }

    override func saveCache() {
        if self.adapter.rows.count > 0 {
            if let list = self.list {
                let key = "lists:\(list.id)"
                let statuses = self.adapter.statuses
                let dictionary = ["statuses": ( statuses.count > 100 ? Array(statuses[0 ..< 100]) : statuses ).map({ $0.dictionaryValue })]
                KeyClip.save(key, dictionary: dictionary)
                NSLog("\(key) saveCache.")
            }
        }
    }

    override func loadCache(success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        if let list = self.list {
            let key = "lists:\(list.id)"
            Async.background {
                if let cache = KeyClip.load(key) as NSDictionary? {
                    if let statuses = cache["statuses"] as? [[String: AnyObject]] {
                        success(statuses: statuses.map({ TwitterStatus($0) }))
                        return
                    }
                }
                success(statuses: [TwitterStatus]())

                Async.background(after: 0.5, block: { () -> Void in
                    self.loadData(nil)
                })
            }
        } else {
            success(statuses: [])
        }
    }

    override func loadData(maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        guard let list = list else {
            return
        }
        Twitter.getListsStatuses(list.id, maxID: maxID, success: success, failure: failure)
    }

    override func loadData(sinceID sinceID: String?, maxID: String?, success: ((statuses: [TwitterStatus]) -> Void), failure: ((error: NSError) -> Void)) {
        guard let list = list else {
            return
        }
        Twitter.getListsStatuses(list.id, sinceID: sinceID, maxID: maxID, success: success, failure: failure)
    }

    override func accept(status: TwitterStatus) -> Bool {
        return false
    }
}
