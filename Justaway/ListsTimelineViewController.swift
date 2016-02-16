import UIKit
import KeyClip
import EventBox
import Async

class ListsTimelineTableViewController: StatusTableViewController {

    var list: TwitterList?

    override func viewDidLoad() {
        super.viewDidLoad()
        cacheLoaded = true // no cache
        adapter.scrollEnd(tableView) // contentInset call scrollViewDidScroll, but call scrollEnd
    }

    override func saveCache() {
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
