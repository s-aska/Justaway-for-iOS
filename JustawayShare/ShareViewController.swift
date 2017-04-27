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
    var imageData: Data?
    var account: ACAccount?
    var accounts = [ACAccount]()
    let previewView = UIImageView()
    var shareURL: URL?
    var indicatorView: UIActivityIndicatorView?
    let session: URLSession = {
        let configuration = URLSessionConfiguration.default
        return URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
    }()

    // MARK: - UIViewController

    override func viewDidLoad() {
        previewView.clipsToBounds = true
        previewView.contentMode = .scaleAspectFill
        previewView.addConstraints([
            NSLayoutConstraint(item: previewView, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 60),
            NSLayoutConstraint(item: previewView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 60)
        ])
        previewView.isUserInteractionEnabled = true
        previewView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: #selector(removeImage)))
    }

    // MARK: - SLComposeServiceViewController

    override func isContentValid() -> Bool {
        self.calcRemaining()
        return self.account != nil && (self.charactersRemaining?.intValue ?? 0) > 0
    }

    func calcRemaining() {
        let text = textView.text ?? ""
        let oldValue = Int(self.charactersRemaining ?? 0)
        let newValue = 140 - Twitter.count(text, hasImage: hasImage)
        if self.charactersRemaining == nil || oldValue != newValue {
            self.charactersRemaining = newValue as NSNumber
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
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
    }

    override func loadPreviewView() -> UIView! {
        loadNowPlayingFromShareContent()
        loadInputItems()
        return previewView
    }

    override func configurationItems() -> [Any]! {
        let twitter = configurationItemsTwitterAccount()
        return [twitter]
    }

    func configurationItemsTwitterAccount() -> SLComposeSheetConfigurationItem {
        let ud = UserDefaults.standard
        let userID = ud.object(forKey: ShareViewController.keyUserID) as? String ?? ""
        let twitter = SLComposeSheetConfigurationItem()
        twitter?.title = "Account"
        twitter?.tapHandler = {
            if self.accounts.count == 0 {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.showDialog("Error", message: "Twitter requires you to authorize Justaway to use your account.")
                })
                return
            }
            let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(
                title: "Close",
                style: .cancel,
                handler: { action in
            }))
            for twitterAccount in self.accounts {
                let account = twitterAccount
                actionSheet.addAction(UIAlertAction(
                    title: account.username,
                    style: .default,
                    handler: { action in
                        twitter?.value = account.username
                        self.account = account
                        if let userID = account.value(forKeyPath: "properties.user_id") as? String {
                            ud.set(userID, forKey: ShareViewController.keyUserID)
                            ud.synchronize()
                        }
                }))
            }
            DispatchQueue.main.async(execute: { () -> Void in
                self.present(actionSheet, animated: true, completion: nil)
            })
        }
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountType(withAccountTypeIdentifier: ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccounts(with: accountType, options: nil) {
            granted, error in
            if granted {
                let twitterAccounts = accountStore.accounts(with: accountType) as? [ACAccount] ?? []
                if let account = twitterAccounts.first {
                    if !userID.isEmpty {
                        for account in twitterAccounts {
                            let accountUserID = account.value(forKeyPath: "properties.user_id") as? String ?? ""
                            if accountUserID == userID {
                                DispatchQueue.main.async(execute: { () -> Void in
                                    twitter?.value = account.username
                                })
                                self.account = account
                                break
                            }
                        }
                    }
                    if self.account == nil {
                        self.account = account
                        DispatchQueue.main.async(execute: { () -> Void in
                            twitter?.value = account.username
                            self.validateContent()
                        })
                    }
                } else {
                    DispatchQueue.main.async(execute: { () -> Void in
                        self.showDialog("Error", message: "There are no Twitter accounts configured. You can add or create a Twitter account in Settings.")
                    })
                }
                self.accounts = twitterAccounts
            } else {
                DispatchQueue.main.async(execute: { () -> Void in
                    self.showDialog("Error", message: "Twitter requires you to authorize Justaway to use your account.")
                })
            }
        }
        return twitter!
    }

    // MARK: - Public

    func loadNowPlayingFromShareContent() {
        GooglePlayMusic.loadMetaFromShareURL(contentText) { (music) in
            DispatchQueue.main.async(execute: { () -> Void in
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

    func loadInputURL(_ provider: NSItemProvider) {
        if provider.hasItemConformingToTypeIdentifier("public.url") {
            provider.loadItem(forTypeIdentifier: "public.url", options: nil, completionHandler: {
                (item, error) in
                guard let itemURL = item as? URL else {
                    return
                }
                if !itemURL.absoluteString.hasPrefix("http") {
                    return
                }
                if self.textView.text.isEmpty && self.shareURL == nil {
                    self.loadPageTitle(itemURL)
                }
                self.shareURL = itemURL
                DispatchQueue.main.async(execute: { () -> Void in
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

    func loadInputImage(_ provider: NSItemProvider) {
        for key in ["public.jpeg", "public.image"] {
            if provider.hasItemConformingToTypeIdentifier(key) {
                provider.loadItem(forTypeIdentifier: key, options: nil, completionHandler: {
                    (item, error) in
                    switch item {
                    case let imageURL as URL:
                        self.loadImageURL(imageURL)
                    case let image as UIImage:
                        self.loadImage(image)
                    case let data as Data:
                        self.loadImageData(data)
                    default:
                        break
                    }
                })
            }
        }
    }

    // SFSafariViewController don't set page title to self.textView.text
    func loadPageTitle(_ pageURL: URL) {
        if let ud = UserDefaults.init(suiteName: "group.pw.aska.justaway"),
            let title = ud.object(forKey: "shareTitle") as? String,
            let shareURL = ud.url(forKey: "shareURL"), pageURL == shareURL {
            OperationQueue.main.addOperation {
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
        var urlComponents = URLComponents(string: "https://tyxd8v3j67.execute-api.ap-northeast-1.amazonaws.com/prod/ogp")!
        urlComponents.queryItems = [
            URLQueryItem.init(name: "url", value: pageURL.absoluteString)
        ]
        guard let url = urlComponents.url else {
            return
        }
        let req = NSMutableURLRequest.init(url: url)
        req.httpMethod = "GET"
        let ogpCompletion = { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                self.stopIndicator()
                return
            }
            do {
                let json: Any = try JSONSerialization.jsonObject(with: data, options: [])
                if let dic = json as? NSDictionary, let title = dic["title"] as? String {
                    OperationQueue.main.addOperation {
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
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        session.dataTask(with: url, completionHandler: ogpCompletion).resume()
    }

    func startIndicator() {
        let indicatorView = UIActivityIndicatorView(frame: CGRect.init(x: 0, y: 0, width: 80, height: 80))
        indicatorView.layer.cornerRadius = 10
        indicatorView.activityIndicatorViewStyle = .whiteLarge
        indicatorView.hidesWhenStopped = true
        indicatorView.center = CGPoint.init(x: self.view.center.x, y: self.view.center.y - 108)
        indicatorView.backgroundColor = UIColor(white: 0, alpha: 0.6)
        self.indicatorView = indicatorView
        DispatchQueue.main.async(execute: { () -> Void in
            self.view.addSubview(indicatorView)
            indicatorView.startAnimating()
        })
    }

    func stopIndicator() {
        DispatchQueue.main.async(execute: { () -> Void in
            self.indicatorView?.stopAnimating()
            self.indicatorView?.removeFromSuperview()
        })
    }

    func loadImage(_ image: UIImage) {
        self.imageData = UIImagePNGRepresentation(image)
        self.hasImage = true
        DispatchQueue.main.async(execute: { () -> Void in
            self.previewView.image = image
            self.validateContent()
        })
    }

    func loadImageData(_ data: Data) {
        self.imageData = data
        self.hasImage = true
        let image = UIImage(data: data)
        DispatchQueue.main.async(execute: { () -> Void in
            self.previewView.image = image
            self.validateContent()
        })
    }

    func loadImageURL(_ imageURL: URL) {
        let completion = { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            guard let data = data else {
                return
            }
            self.loadImageData(data)
        }
        self.session.dataTask(with: imageURL, completionHandler: completion).resume()
    }

    func removeImage() {
        hasImage = false
        imageData = nil
        DispatchQueue.main.async(execute: { () -> Void in
            self.previewView.image = nil
            self.previewView.removeFromSuperview()
            self.validateContent()
        })
    }

    func showDialog(_ title: String, message: String) {
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actionSheet.addAction(UIAlertAction(
            title: "Close",
            style: .cancel,
            handler: { action in
        }))
        self.present(actionSheet, animated: true, completion: nil)
    }
}
