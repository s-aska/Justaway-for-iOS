//
//  ShareViewController.swift
//  JustawayShare
//
//  Created by Shinichiro Aska on 3/22/16.
//  Copyright © 2016 Shinichiro Aska. All rights reserved.
//

import UIKit
import Social
import Accounts

class ShareViewController: SLComposeServiceViewController {

    // MARK: Properties

    static let keyUserID = "keyUserID"
    var hasImage = false
    var imageData: NSData?
    var account: ACAccount?
    var accounts = [ACAccount]()
    let previewView = UIImageView()
    var shareURL: NSURL?
    var indicatorView: UIActivityIndicatorView?
    let session: NSURLSession = {
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        return NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }()

    // MARK: - UIViewController

    override func viewDidLoad() {
        previewView.clipsToBounds = true
        previewView.contentMode = .ScaleAspectFill
        previewView.addConstraints([
            NSLayoutConstraint(item: previewView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1.0, constant: 60),
            NSLayoutConstraint(item: previewView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1.0, constant: 60)
        ])
        previewView.userInteractionEnabled = true
        previewView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(removeImage)))
    }

    // MARK: - SLComposeServiceViewController

    override func isContentValid() -> Bool {
        self.calcRemaining()
        return self.account != nil && (self.charactersRemaining?.integerValue ?? 0) > 0
    }

    func calcRemaining() {
        let text = textView.text
        let oldValue = Int(self.charactersRemaining ?? 0)
        let newValue = 140 - Twitter.count(text, hasImage: hasImage)
        if self.charactersRemaining == nil || oldValue != newValue {
            self.charactersRemaining = newValue
        }
    }

    override func didSelectPost() {
        if let account = account {
            if let data = self.imageData {
                Twitter.updateStatusWithMedia(account, status: contentText, imageData: data)
            } else {
                Twitter.updateStatus(account, status: contentText)
            }
        }
        self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
    }

    override func loadPreviewView() -> UIView! {
        loadNowPlayingFromShareContent()
        loadInputItems()
        return previewView
    }

    override func configurationItems() -> [AnyObject]! {
        let twitter = configurationItemsTwitterAccount()
        return [twitter]
    }

    func configurationItemsTwitterAccount() -> SLComposeSheetConfigurationItem {
        let ud = NSUserDefaults.standardUserDefaults()
        let userID = ud.objectForKey(ShareViewController.keyUserID) as? String ?? ""
        let twitter = SLComposeSheetConfigurationItem()
        twitter.title = "Account"
        twitter.tapHandler = {
            if self.accounts.count == 0 {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.showDialog("Error", message: "Twitter requires you to authorize Justaway to use your account.")
                })
                return
            }
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
            actionSheet.addAction(UIAlertAction(
                title: "Close",
                style: .Cancel,
                handler: { action in
            }))
            for twitterAccount in self.accounts {
                let account = twitterAccount
                actionSheet.addAction(UIAlertAction(
                    title: account.username,
                    style: .Default,
                    handler: { action in
                        twitter.value = account.username
                        self.account = account
                        if let userID = account.valueForKeyPath("properties.user_id") as? String {
                            ud.setObject(userID, forKey: ShareViewController.keyUserID)
                            ud.synchronize()
                        }
                }))
            }
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.presentViewController(actionSheet, animated: true, completion: nil)
            })
        }
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
            granted, error in
            if granted {
                let twitterAccounts = accountStore.accountsWithAccountType(accountType) as? [ACAccount] ?? []
                if let account = twitterAccounts.first {
                    if !userID.isEmpty {
                        for account in twitterAccounts {
                            let accountUserID = account.valueForKeyPath("properties.user_id") as? String ?? ""
                            if accountUserID == userID {
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    twitter.value = account.username
                                })
                                self.account = account
                                break
                            }
                        }
                    }
                    if self.account == nil {
                        self.account = account
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            twitter.value = account.username
                            self.validateContent()
                        })
                    }
                } else {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.showDialog("Error", message: "There are no Twitter accounts configured. You can add or create a Twitter account in Settings.")
                    })
                }
                self.accounts = twitterAccounts
            } else {
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    self.showDialog("Error", message: "Twitter requires you to authorize Justaway to use your account.")
                })
            }
        }
        return twitter
    }

    // MARK: - Public

    func loadNowPlayingFromShareContent() {
        GooglePlayMusic.loadMetaFromShareURL(contentText) { (music) in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.textView.text = "#NowPlaying " + music.titleWithArtist + "\n" + music.musicURL.absoluteString
                self.textView.selectedRange = NSRange.init(location: 0, length: 0)
                self.validateContent()
            })

            if let imageURL = music.albumURL {
                self.loadImageURL(imageURL)
            }
        }
    }

    func loadInputItems() {
        guard let inputItems = self.extensionContext?.inputItems else {
            return
        }
        for inputItem in inputItems {
            guard let item = inputItem as? NSExtensionItem else {
                continue
            }
            guard let attachments = item.attachments else {
                continue
            }
            for attachment in attachments {
                guard let provider = attachment as? NSItemProvider else {
                    continue
                }
                loadInputURL(provider)
                loadInputImage(provider)
            }
        }
    }

    func loadInputURL(provider: NSItemProvider) {
        if provider.hasItemConformingToTypeIdentifier("public.url") {
            provider.loadItemForTypeIdentifier("public.url", options: nil, completionHandler: {
                (item, error) in
                guard let itemURL = item as? NSURL else {
                    return
                }
                if !itemURL.absoluteString.hasPrefix("http") {
                    return
                }
                if self.textView.text.isEmpty && self.shareURL == nil {
                    self.loadPageTitle(itemURL)
                }
                self.shareURL = itemURL
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if self.textView.text.isEmpty {
                        self.textView.text = itemURL.absoluteString
                    } else {
                        self.textView.text = self.textView.text + " " + itemURL.absoluteString
                    }
                    self.textView.selectedRange = NSRange.init(location: 0, length: 0)
                    self.textView.setContentOffset(CGPoint.zero, animated: false)
                    self.validateContent()
                })
            })
        }
    }

    func loadInputImage(provider: NSItemProvider) {
        for key in ["public.jpeg", "public.image"] {
            if provider.hasItemConformingToTypeIdentifier(key) {
                provider.loadItemForTypeIdentifier(key, options: nil, completionHandler: {
                    (item, error) in
                    switch item {
                    case let imageURL as NSURL:
                        self.loadImageURL(imageURL)
                    case let image as UIImage:
                        self.loadImage(image)
                    case let data as NSData:
                        self.loadImageData(data)
                    default:
                        break
                    }
                })
            }
        }
    }

    // SFSafariViewController don't set page title to self.textView.text
    func loadPageTitle(pageURL: NSURL) {
        if let ud = NSUserDefaults.init(suiteName: "group.pw.aska.justaway"),
            title = ud.objectForKey("shareTitle") as? String,
            shareURL = ud.URLForKey("shareURL") where pageURL == shareURL {
            NSOperationQueue.mainQueue().addOperationWithBlock {
                if self.textView.text.isEmpty {
                    self.textView.text = title
                } else {
                    self.textView.text = title + " " + self.textView.text
                }
                self.textView.selectedRange = NSRange.init(location: 0, length: 0)
                self.textView.setContentOffset(CGPoint.zero, animated: false)
                self.validateContent()
            }
            return
        }

        // Not Justaway.app's SFSafariViewController
        let urlComponents = NSURLComponents(string: "https://tyxd8v3j67.execute-api.ap-northeast-1.amazonaws.com/prod/ogp")!
        urlComponents.queryItems = [
            NSURLQueryItem.init(name: "url", value: pageURL.absoluteString),
        ]
        guard let url = urlComponents.URL else {
            return
        }
        let req = NSMutableURLRequest.init(URL: url)
        req.HTTPMethod = "GET"
        let ogpCompletion = { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard let data = data else {
                self.stopIndicator()
                return
            }
            do {
                let json: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                if let dic = json as? NSDictionary, title = dic["title"] as? String {
                    NSOperationQueue.mainQueue().addOperationWithBlock {
                        self.textView.text = title + " " + self.textView.text
                        self.textView.selectedRange = NSRange.init(location: 0, length: 0)
                        self.textView.setContentOffset(CGPoint.zero, animated: false)
                        self.validateContent()
                        self.stopIndicator()
                    }
                } else {
                    self.stopIndicator()
                }
            } catch _ as NSError {
                self.stopIndicator()
                return
            }
        }
        startIndicator()
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        session.dataTaskWithRequest(req, completionHandler: ogpCompletion).resume()
    }

    func startIndicator() {
        let indicatorView = UIActivityIndicatorView(frame: CGRect.init(x: 0, y: 0, width: 80, height: 80))
        indicatorView.layer.cornerRadius = 10
        indicatorView.activityIndicatorViewStyle = .WhiteLarge
        indicatorView.hidesWhenStopped = true
        indicatorView.center = CGPoint.init(x: self.view.center.x, y: self.view.center.y - 108)
        indicatorView.backgroundColor = UIColor(white: 0, alpha: 0.6)
        self.indicatorView = indicatorView
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.view.addSubview(indicatorView)
            indicatorView.startAnimating()
        })
    }

    func stopIndicator() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.indicatorView?.stopAnimating()
            self.indicatorView?.removeFromSuperview()
        })
    }

    func loadImage(image: UIImage) {
        self.imageData = UIImagePNGRepresentation(image)
        self.hasImage = true
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.previewView.image = image
            self.validateContent()
        })
    }

    func loadImageData(data: NSData) {
        self.imageData = data
        self.hasImage = true
        let image = UIImage(data: data)
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.previewView.image = image
            self.validateContent()
        })
    }

    func loadImageURL(imageURL: NSURL) {
        let completion = { (data: NSData?, response: NSURLResponse?, error: NSError?) -> Void in
            guard let data = data else {
                return
            }
            self.loadImageData(data)
        }
        self.session.dataTaskWithURL(imageURL, completionHandler: completion).resume()
    }

    func removeImage() {
        hasImage = false
        imageData = nil
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.previewView.image = nil
            self.previewView.removeFromSuperview()
            self.validateContent()
        })
    }

    func showDialog(title: String, message: String) {
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        actionSheet.addAction(UIAlertAction(
            title: "Close",
            style: .Cancel,
            handler: { action in
        }))
        self.presentViewController(actionSheet, animated: true, completion: nil)
    }
}
