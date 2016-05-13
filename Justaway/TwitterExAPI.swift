import UIKit
import KeyClip
import TwitterAPI
import SwiftyJSON

extension Twitter {
    class func getActivity(maxID maxID: String? = nil, sinceID: String? = nil, success: ([TwitterStatus]) -> Void, failure: (NSError) -> Void) {
        guard let account = AccountSettingsStore.get()?.account() else {
            success([])
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
        let success = { (json: JSON) -> Void in
            guard let array = json.array else {
                success([])
                return
            }
            var userMap = [String: TwitterUser]()
            let sourceIds = Array(Set(
                array
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
                        sourceID = event["source_id"].int64?.stringValue,
                        eventName = event["event"].string {
                        if let status = statusMap[statusID] {
                            switch eventName {
                            case "reply", "retweet", "quoted_tweet":
                                events.append(status)
                            case "retweeted_retweet":
                                if let source = userMap[sourceID] {
                                    events.append(TwitterStatus.init(status, type: .Normal, event: eventName, actionedBy: source))
                                }
                            case "favorite", "favorited_retweet":
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
        let urlComponents = NSURLComponents(string: "https://justaway.info/api/activity/list.json")!
        urlComponents.queryItems = parameters.map({ NSURLQueryItem.init(name: $0.0, value: $0.1) })
        guard let url = urlComponents.URL else {
            success([])
            return
        }
        let req = NSMutableURLRequest.init(URL: url)
        req.setValue(account.exToken, forHTTPHeaderField: "X-Justaway-API-Token")
        NSURLSession.sharedSession().dataTaskWithRequest(req) { (data, response, error) in
            if let error = error {
                failure(error)
            } else if let data = data {
                let HTTPResponse = response as? NSHTTPURLResponse
                let HTTPStatusCode = HTTPResponse?.statusCode ?? 0
                if HTTPStatusCode == 200 {
                    let json = JSON(data: data)
                    success(json)
                } else {
                    let error = NSError.init(domain: NSURLErrorDomain, code: HTTPStatusCode, userInfo: [
                        NSLocalizedDescriptionKey: "Justaway Ex API Error\nURL:\(url)\nHTTP StatusCode:\(HTTPStatusCode)",
                        NSLocalizedRecoverySuggestionErrorKey: "-"
                        ])
                    failure(error)
                }
            }
        }.resume()
    }
}
