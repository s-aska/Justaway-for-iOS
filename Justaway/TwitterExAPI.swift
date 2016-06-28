import UIKit
import KeyClip
import TwitterAPI
import SwiftyJSON

extension Twitter {

    struct TwitterEvent {
        let status: TwitterStatus
        let createdAt: Int
        init (status: TwitterStatus, createdAt: Int) {
            self.status = status
            self.createdAt = createdAt
        }
    }

    class func getActivity(maxID maxID: String? = nil, sinceID: String? = nil, maxMentionID: String?, success: (statuses: [TwitterStatus], maxMentionID: String?) -> Void, failure: (NSError) -> Void) {
        guard let account = AccountSettingsStore.get()?.account() else {
            success(statuses: [], maxMentionID: nil)
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
                success(statuses: [], maxMentionID: nil)
                return
            }
            var userMap = [String: TwitterUser]()
            let sourceIds = Array(Set(
                array
                    .flatMap({ $0["source_id"].int64?.stringValue })
                ))
            let statusIDs = Array(Set(array.flatMap { $0["target_object_id"].int64?.stringValue }))
            let successStatuses = { (statuses: [TwitterStatus]) -> Void in
                var replyMap = [String: Bool]()
                var statusMap = [String: TwitterStatus]()
                for status in statuses {
                    statusMap[status.referenceStatusID ?? status.statusID] = status
                }
                var events = [TwitterEvent]()
                for event in array {
                    if let statusID = event["target_object_id"].int64?.stringValue,
                        sourceID = event["source_id"].int64?.stringValue,
                        eventName = event["event"].string,
                        createdAt = event["created_at"].int {
                        if let status = statusMap[statusID] {
                            if eventName == "reply" {
                                replyMap[status.statusID] = true
                            }
                            switch eventName {
                            case "reply", "retweet", "quoted_tweet":
                                events.append(TwitterEvent(status: status, createdAt: createdAt))
                            case "retweeted_retweet":
                                if let source = userMap[sourceID] {
                                    let newStatus = TwitterStatus(status, type: .Normal, event: eventName, actionedBy: source, isRoot: false)
                                    events.append(TwitterEvent(status: newStatus, createdAt: createdAt))
                                }
                            case "favorite", "favorited_retweet":
                                if let source = userMap[sourceID] {
                                    let newStatus = TwitterStatus(status, type: .Favorite, event: eventName, actionedBy: source, isRoot: false)
                                    events.append(TwitterEvent(status: newStatus, createdAt: createdAt))
                                }
                            default:
                                break
                            }
                        }
                    }
                }
                let successMention = { (statuses: [TwitterStatus]) -> Void in
                    let newMaxMentionID = statuses.last?.statusID
                    let mentionEvents = statuses
                        .filter { replyMap[$0.statusID] == nil }
                        .map { TwitterEvent(status: $0, createdAt: Int($0.createdAt.date.timeIntervalSince1970)) }
                    let newStatuses = (events + mentionEvents).sort({ (s0, s1) -> Bool in
                        return s0.createdAt > s1.createdAt
                    }).map { $0.status }
                    NSLog("[getActivity] maxID:\(maxID) sinceID:\(sinceID) maxMentionID:\(maxMentionID) newMaxMentionID:\(newMaxMentionID) mentions:\(statuses.count) => \(mentionEvents.count) => \(newStatuses.count)")
                    success(statuses: newStatuses, maxMentionID: newMaxMentionID)
                }
                Twitter.getMentionTimeline(sinceID: nil, maxID: maxMentionID, success: successMention, failure: failure)
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

    class func getFavoriters(status: TwitterStatus, success: ([TwitterUserFull]) -> Void, failure: (NSError) -> Void) {
        guard let account = AccountSettingsStore.get()?.find(status.user.userID) where !account.exToken.isEmpty else {
            success([])
            return
        }
        let idsSuccess = { (json: JSON) in
            guard let ids = json["ids"].array?.map({ $0.string ?? "" }).filter({ !$0.isEmpty }) else {
                success([])
                return
            }
            Twitter.getUsers(ids, success: success, failure: failure)
        }
        let urlComponents = NSURLComponents(string: "https://justaway.info/api/statuses/favoriters/ids.json")!
        urlComponents.queryItems = [NSURLQueryItem(name: "id", value: status.statusID)]
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
                    idsSuccess(json)
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
