import Foundation

class Notification {
    
    // MARK: - Singleton
    
    struct Static {
        static let instance = Notification()
        static let queue = dispatch_queue_create("Notification.Static.instance.cache", DISPATCH_QUEUE_SERIAL)
    }
    
    var cache = [UInt:[NSObjectProtocol]]()
    
    // MARK: - addObserverForName
    
    class func on(target: AnyObject, name: String, queue: NSOperationQueue?, callback: ((NSNotification!) -> Void)) {
        let id = ObjectIdentifier(target).uintValue()
        
        dispatch_sync(Static.queue) {
            let observer = NSNotificationCenter.defaultCenter().addObserverForName(name, object: nil, queue: queue, usingBlock: callback)
            if let observers = Static.instance.cache[id] {
                Static.instance.cache[id] = observers + [observer]
            } else {
                Static.instance.cache[id] = [observer]
            }
        }
    }
    
    class func onMainThread(target: AnyObject, name: String, callback: ((NSNotification!) -> Void)) {
        Notification.on(target, name: name, queue: NSOperationQueue.mainQueue(), callback: callback)
    }
    
    class func onBackgroundThread(target: AnyObject, name: String, callback: ((NSNotification!) -> Void)) {
        Notification.on(target, name: name, queue: NSOperationQueue(), callback: callback)
    }
    
    // MARK: - removeObserver
    
    class func off(target: AnyObject) {
        let id = ObjectIdentifier(target).uintValue()
        
        dispatch_sync(Static.queue) {
            if let observers = Static.instance.cache[id] {
                for observer in observers {
                    NSNotificationCenter.defaultCenter().removeObserver(observer)
                }
                Static.instance.cache.removeValueForKey(id)
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
