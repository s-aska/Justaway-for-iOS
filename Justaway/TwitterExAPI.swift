import UIKit
import KeyClip
import TwitterAPI
import SwiftyJSON

extension Twitter {
    class func getActivity(maxID maxID: String? = nil, sinceID: String? = nil, success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        guard let account = AccountSettingsStore.get()?.account() else {
            return
        }
        var parameters: [String: String] = [:]
        if let maxID = maxID {
            parameters["max_id"] = maxID
            parameters["count"] = "200"
        }
        if let sinceID = sinceID {
            parameters["since_id"] = sinceID
            parameters["count"] = "200"
        }
        let failure = { (error: NSError) -> Void in
            ErrorAlert.show(error)
        }
        let success = { (json: JSON) -> Void in
            guard let array = json.array else {
                return
            }
            var userMap = [String: TwitterUser]()
            let sourceIds = Array(Set(
                array
                    .filter({ $0["event"].string ?? "" == "favorite" })
                    .flatMap({ $0["source_id"].int64?.stringValue })
            ))
            let statusIDs = Array(Set(array.flatMap { $0["target_object_id"].int64?.stringValue }))
            let successStatuses = { (statuses: [TwitterStatus]) -> Void in
                var statusMap = [String: TwitterStatus]()
                for status in statuses {
                    statusMap[status.referenceStatusID ?? status.statusID] = status
                }
                var events = [TwitterStatus]()
                for event in array {
                    if let statusID = event["target_object_id"].int64?.stringValue,
                        let sourceID = event["source_id"].int64?.stringValue,
                        let eventName = event["event"].string {
                        if let status = statusMap[statusID] {
                            switch eventName {
                            case "reply", "retweet", "favorited_retweet", "retweeted_retweet", "quoted_tweet":
                                events.append(status)
                            case "favorite":
                                if let source = userMap[sourceID] {
                                    events.append(TwitterStatus.init(status, type: .Favorite, event: eventName, actionedBy: source))
                                }
                            default:
                                break
                            }
                        }
                    }
                }
                success(events)
            }
            let successUsers = { (users: [TwitterUser]) -> Void in
                for user in users {
                    userMap[user.userID] = user
                }
                getStatuses(statusIDs, success: successStatuses, failure: failure)
            }
            if sourceIds.count > 0 {
                getUsers(sourceIds, success: successUsers, failure: failure)
            } else {
                successUsers([])
            }

//            if maxID == nil {
//                let dictionary = ["events": statuses.map({ $0.dictionaryValue })]
//                if KeyClip.save("activity", dictionary: dictionary) {
//                    NSLog("activity cache success.")
//                }
//            }
        }
        let url = NSURL(string: "https://justaway.info/api/activity/list.json")!
        let req = NSMutableURLRequest(URL: url)
        req.setValue(account.exToken, forHTTPHeaderField: "X-Justaway-API-Token")
        NSURLSession.sharedSession().dataTaskWithRequest(req) { (data, response, error) in
            if let error = error {
                ErrorAlert.show(error)
            } else if let data = data {
                let json = JSON(data: data)
                if json.error != nil {
                    let HTTPResponse = response as? NSHTTPURLResponse
                    let HTTPStatusCode = HTTPResponse?.statusCode ?? 0
                    let error = NSError.init(domain: NSURLErrorDomain, code: HTTPStatusCode, userInfo: [
                        NSLocalizedDescriptionKey: "Twitter API Error\nURL:\(url)\nHTTP StatusCode:\(HTTPStatusCode)",
                        NSLocalizedRecoverySuggestionErrorKey: "-"
                        ])
                    ErrorAlert.show("Twitter API Error", message: error.localizedDescription)
                } else if let errors = json["errors"].array {
                    let code = errors[0]["code"].int ?? 0
                    let message = errors[0]["message"].string ?? "Unknown"
                    let HTTPResponse = response as? NSHTTPURLResponse
                    let HTTPStatusCode = HTTPResponse?.statusCode ?? 0
                    var localizedDescription = "Twitter API Error\nErrorMessage:\(message)\nErrorCode:\(code)\nURL:\(url)\nHTTP StatusCode:\(HTTPStatusCode)"
                    var recoverySuggestion = "-"
                    if HTTPStatusCode == 401 && code == 89 {
                        localizedDescription = "Was revoked access @\(account.screenName)"
                        if (account.client as? OAuthClient) != nil {
                            recoverySuggestion = "1. Open the menu (upper left).\n2. Open the Accounts.\n3. Tap the [Add]\n4. Choose via Justaway for iOS\n5. Authorize app."
                        } else {
                            recoverySuggestion = "1. Tap the Home button.\n2. Open the [Settings].\n3. Open the [Twitter].\n4. Delete all account.\n5. Add all account.\n6. Open the Justaway."
                        }
                    }
                    let error = NSError.init(domain: NSURLErrorDomain, code: HTTPStatusCode, userInfo: [
                        NSLocalizedDescriptionKey: localizedDescription,
                        NSLocalizedRecoverySuggestionErrorKey: recoverySuggestion
                        ])
                    ErrorAlert.show("Twitter API Error", message: error.localizedDescription)
                } else {
                    success(json)
                }
            }
        }.resume()
    }
}
