import UIKit
import SwifteriOS
import Pinwheel
import KeyClip
import EventBox

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        Pinwheel.setup(
            Pinwheel.Configuration.Builder()
                .maxConcurrent(5)
                .defaultTimeoutIntervalForRequest(5)
                //.debug()
                .build())
        
        Twitter.setup()
        
        #if DEBUG
            // Pinwheel.DiskCache.sharedInstance().clear()
            KeyClip.printError(true)
            NSLog("debug")
        #endif
        
        ThemeController.apply()
        
        GenericSettings.configure()
        
        return true
    }
    
    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        NSLog("applicationWillResignActive")
    }
    
    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        NSLog("applicationDidEnterBackground")
        
        EventBox.post("applicationDidEnterBackground")
    }
    
    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        NSLog("applicationWillEnterForeground")
        
        Twitter.startStreamingIfEnable()
    }
    
    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSLog("applicationDidBecomeActive")
        
        Async.background(after: 1) { () -> Void in
            Twitter.startStreamingIfEnable()
        }
        
        application.idleTimerDisabled = true // don't sleep
    }
    
    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        NSLog("applicationWillTerminate")
        
        application.idleTimerDisabled = false
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if url.absoluteString.hasPrefix("justaway://success") ?? false {
            Swifter.handleOpenURL(url)
        }
        
        return true
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        
        // observe statusBar touch
        if let touch = touches.first {
            let location = touch.locationInView(self.window)
            if CGRectContainsPoint(UIApplication.sharedApplication().statusBarFrame, location) {
                EventBox.post(EventStatusBarTouched)
            }
        }
    }
}
