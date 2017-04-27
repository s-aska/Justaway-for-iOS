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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        KingfisherManager.shared.cache.maxDiskCacheSize = 50 * 1024 * 1024 // 50mb

        Twitter.setup()

        #if DEBUG
            KeyClip.printError(true)
            NSLog("debug")
        #endif

        ThemeController.apply()

        GenericSettings.configure()

        if let _ = launchOptions?[UIApplicationLaunchOptionsKey.remoteNotification] {
            // アプリが起動していない時にpush通知が届き、push通知から起動した場合
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        NSLog("applicationWillResignActive")
        EventBox.post(Notification.Name(rawValue: "applicationWillResignActive"))
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        NSLog("applicationDidEnterBackground")

        EventBox.post(Notification.Name(rawValue: "applicationDidEnterBackground"))
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        NSLog("applicationWillEnterForeground")

        EventBox.post(Notification.Name(rawValue: "applicationWillEnterForeground"))
//        Twitter.startStreamingIfEnable()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        NSLog("applicationDidBecomeActive")
        EventBox.post(Notification.Name(rawValue: "applicationDidBecomeActive"))

        Async.background(after: 1) { () -> Void in
            Twitter.startStreamingIfEnable()
        }

        application.isIdleTimerDisabled = GenericSettings.get().disableSleep

        AccountSettingsStore.setup()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        NSLog("applicationWillTerminate")

        application.isIdleTimerDisabled = false
    }

    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if url.absoluteString.hasPrefix("justaway://success") {
            SafariOAuthURLHandler.callback(url)
        }
        if url.absoluteString.hasPrefix("justaway://ex/callback/") {
            SafariExURLHandler.callback(url)
        }

        return true
    }

    // Push通知の登録が完了した場合、deviceTokenが返される
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let deviceTokenString: String = (deviceToken.description as NSString)
            .trimmingCharacters(in: CharacterSet(charactersIn: "<>"))
            .replacingOccurrences(of: " ", with: "") as String
        NSLog("deviceToken: \(deviceTokenString)")
        guard let settings = AccountSettingsStore.get() else {
            return
        }
        for account in settings.accounts {
            if account.exToken.isEmpty {
                continue
            }
            let currentDevice = UIDevice.current
            let deviceName = [
                currentDevice.systemName,
                currentDevice.systemVersion,
                currentDevice.model
            ].joined(separator: "/")
            var urlComponents = URLComponents(string: "https://justaway.info/api/devices.json")!
            urlComponents.queryItems = [
                URLQueryItem(name: "deviceName", value: deviceName),
                URLQueryItem(name: "deviceType", value: deviceType),
                URLQueryItem(name: "deviceToken", value: deviceTokenString)
            ]
            guard let url = urlComponents.url else {
                continue
            }
            var req = URLRequest.init(url: url)
            req.httpMethod = "PUT"
            req.setValue(account.exToken, forHTTPHeaderField: "X-Justaway-API-Token")
            URLSession.shared.dataTask(with: req, completionHandler: { (data, response, error) in
            }).resume()
        }
    }

    // Push通知が利用不可であればerrorが返ってくる
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("error: " + "\(error)")
    }

    // Push通知受信時とPush通知をタッチして起動したときに呼ばれる
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        switch application.applicationState {
        case .inactive:
            // アプリがバックグラウンドにいる状態で、Push通知から起動したとき
            NSLog("didReceiveRemoteNotification Inactive")
            break
        case .active:
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
        case .background:
            // アプリがバックグラウンドにいる状態でPush通知を受信したとき
            NSLog("didReceiveRemoteNotification Background")
            break
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        // observe statusBar touch
        if let touch = touches.first {
            let location = touch.location(in: self.window)
            if UIApplication.shared.statusBarFrame.contains(location) {
                EventBox.post(eventStatusBarTouched)
            }
        }
    }
}
