import UIKit
import KeyClip
import EventBox
import OAuthSwift
import Accounts
import TwitterAPI
import Async
import Kingfisher

#if DEBUG
let deviceType = "APNS_SANDBOX"
#else
let deviceType = "APNS"
#endif

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.

        let downloader = KingfisherManager.sharedManager.downloader
        downloader.requestModifier = {
            (request: NSMutableURLRequest) in
            guard let URL = request.URL else {
                return
            }
            if URL.absoluteString.hasPrefix("https://ton.twitter.com/1.1/ton/data/dm/") {
                if let client = Twitter.client() as? OAuthClient {
                    let authorization = client.oAuthCredential.authorizationHeaderForMethod(.GET, url: URL, parameters: [:])
                    request.setValue(authorization, forHTTPHeaderField: "Authorization")
                }
            }
        }

        Twitter.setup()

        #if DEBUG
            KeyClip.printError(true)
            NSLog("debug")
        #endif

        ThemeController.apply()

        GenericSettings.configure()

        if let _ = launchOptions?[UIApplicationLaunchOptionsRemoteNotificationKey] {
            // アプリが起動していない時にpush通知が届き、push通知から起動した場合
        }

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        NSLog("applicationWillResignActive")
        EventBox.post("applicationWillResignActive")
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

        EventBox.post("applicationWillEnterForeground")
//        Twitter.startStreamingIfEnable()
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSLog("applicationDidBecomeActive")
        EventBox.post("applicationDidBecomeActive")

        Async.background(after: 1) { () -> Void in
            Twitter.startStreamingIfEnable()
        }

        application.idleTimerDisabled = GenericSettings.get().disableSleep

        AccountSettingsStore.setup()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        NSLog("applicationWillTerminate")

        application.idleTimerDisabled = false
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        if url.absoluteString.hasPrefix("justaway://success") ?? false {
            SafariOAuthURLHandler.callback(url)
        }
        if url.absoluteString.hasPrefix("justaway://ex/callback/") ?? false {
            SafariExURLHandler.callback(url)
        }

        return true
    }

    // Push通知の登録が完了した場合、deviceTokenが返される
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let deviceTokenString: String = (deviceToken.description as NSString)
            .stringByTrimmingCharactersInSet(NSCharacterSet(charactersInString: "<>"))
            .stringByReplacingOccurrencesOfString(" ", withString: "") as String
        NSLog("deviceToken: \(deviceTokenString)")
        guard let settings = AccountSettingsStore.get() else {
            return
        }
        for account in settings.accounts {
            if account.exToken.isEmpty {
                continue
            }
            let currentDevice = UIDevice.currentDevice()
            let deviceName = [
                currentDevice.systemName,
                currentDevice.systemVersion,
                currentDevice.model
            ].joinWithSeparator("/")
            let urlComponents = NSURLComponents(string: "https://justaway.info/api/devices.json")!
            urlComponents.queryItems = [
                NSURLQueryItem(name: "deviceName", value: deviceName),
                NSURLQueryItem(name: "deviceType", value: deviceType),
                NSURLQueryItem(name: "deviceToken", value: deviceTokenString)
            ]
            guard let url = urlComponents.URL else {
                continue
            }
            let req = NSMutableURLRequest.init(URL: url)
            req.HTTPMethod = "PUT"
            req.setValue(account.exToken, forHTTPHeaderField: "X-Justaway-API-Token")
            NSURLSession.sharedSession().dataTaskWithRequest(req) { (data, response, error) in
            }.resume()
        }
    }

    // Push通知が利用不可であればerrorが返ってくる
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        NSLog("error: " + "\(error)")
    }

    // Push通知受信時とPush通知をタッチして起動したときに呼ばれる
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        switch application.applicationState {
        case .Inactive:
            // アプリがバックグラウンドにいる状態で、Push通知から起動したとき
            NSLog("didReceiveRemoteNotification Inactive")
            break
        case .Active:
            // アプリ起動時にPush通知を受信したとき
            NSLog("didReceiveRemoteNotification Active")
            let alertMessage: String = {
                if let aps = userInfo["aps"] as? NSDictionary {
                    if let alert = aps["alert"] as? NSDictionary {
                        if let message = alert["message"] as? NSString {
                            return message as String
                        }
                    } else if let alert = aps["alert"] as? NSString {
                        return alert as String
                    }
                }
                return ""
            }()
            if !alertMessage.isEmpty {
                LocalNotification.show(alertMessage)
            }
            break
        case .Background:
            // アプリがバックグラウンドにいる状態でPush通知を受信したとき
            NSLog("didReceiveRemoteNotification Background")
            break
        }
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)

        // observe statusBar touch
        if let touch = touches.first {
            let location = touch.locationInView(self.window)
            if UIApplication.sharedApplication().statusBarFrame.contains(location) {
                EventBox.post(eventStatusBarTouched)
            }
        }
    }
}
