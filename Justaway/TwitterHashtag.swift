import Foundation
import SwifteriOS

struct TwitterHashtag {
    let text: String
    let indices: [Int]
    
    init(_ json: JSONValue) {
        self.text = json["text"].string ?? ""
        self.indices = json["indices"].array?.map({ $0.integer ?? 0 }) ?? [Int]()
    }
}
