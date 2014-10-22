import Foundation

class Notification {
    
    // MARK: - Singleton
    
    struct Static {
        static let instance = Notification()
        static let queue = dispatch_queue_create("Notification.Static.instance.cache", DISPATCH_QUEUE_SERIAL)
    }
    
    var cache = [UInt:[NSObjectProtocol]]()
    
    // MARK: - addObserverForName
    
    class func on(target: AnyObject, name: String, queue: NSOperationQueue?, handler: ((NSNotification!) -> Void)) {
        let id = ObjectIdentifier(target).uintValue()
        
        dispatch_sync(Static.queue) {
            let observer = NSNotificationCenter.defaultCenter().addObserverForName(name, object: nil, queue: queue, usingBlock: handler)
            if let observers = Static.instance.cache[id] {
                Static.instance.cache[id] = observers + [observer]
            } else {
                Static.instance.cache[id] = [observer]
            }
        }
    }
    
    class func onMainThread(target: AnyObject, name: String, handler: ((NSNotification!) -> Void)) {
        Notification.on(target, name: name, queue: NSOperationQueue.mainQueue(), handler: handler)
    }
    
    class func onBackgroundThread(target: AnyObject, name: String, handler: ((NSNotification!) -> Void)) {
        Notification.on(target, name: name, queue: NSOperationQueue(), handler: handler)
    }
    
    // MARK: - removeObserver
    
    class func off(target: AnyObject) {
        let id = ObjectIdentifier(target).uintValue()
        
        dispatch_sync(Static.queue) {
            if let observers = Static.instance.cache.removeValueForKey(id) {
                for observer in observers {
                    NSNotificationCenter.defaultCenter().removeObserver(observer)
                }
            }
        }
    }
    
    // MARK: - postNotificationName
    
    class func post(name: String) {
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: nil)
    }
    
    class func post(name: String, userInfo: [NSObject : AnyObject]?) {
        NSNotificationCenter.defaultCenter().postNotificationName(name, object: nil, userInfo: userInfo)
    }
    
}
