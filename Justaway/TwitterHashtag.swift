import Foundation
import SwifteriOS

struct TwitterHashtag {
    let text: String
    let indices: [Int]
    
    init(_ json: JSONValue) {
        self.text = json["text"].string ?? ""
        self.indices = json["indices"].array?.map({ $0.integer ?? 0 }) ?? [Int]()
    }
    
    init(_ dictionary: [String: AnyObject]) {
        self.text = dictionary["text"] as? String ?? ""
        self.indices = dictionary["indices"] as! [Int]
    }
    
    var dictionaryValue: [String: AnyObject] {
        return [
            "text": text,
            "indices": indices
        ]
    }
}
