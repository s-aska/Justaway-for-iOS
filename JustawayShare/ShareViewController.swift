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

    var hasImage = false
    var albumImageData: NSData?
    var account: ACAccount?
    var accounts = [ACAccount]()
    let previewView = UIImageView()
    let regexp = try! NSRegularExpression(pattern: "<meta property=\"og:([^\"]+)\" content=[\"']([^\"']+)[\"'] ?/?>",
        options: NSRegularExpressionOptions.UseUnicodeWordBoundaries.intersect(NSRegularExpressionOptions.DotMatchesLineSeparators))

    override func isContentValid() -> Bool {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.updateRemaining()
        })
        return self.charactersRemaining != nil && self.charactersRemaining.integerValue > 0
    }

    override func didSelectPost() {
        self.post()
        self.extensionContext!.completeRequestReturningItems([], completionHandler: nil)
    }

    func post() {
        guard let account = account else {
            return
        }
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        guard let updateURL = NSURL(string: "https://api.twitter.com/1.1/statuses/update.json") else {
            return
        }
        guard let mediaURL = NSURL(string: "https://upload.twitter.com/1.1/media/upload.json") else {
            return
        }
        let status = contentText
        if let data = self.albumImageData {
            let media = data.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(rawValue: 0))
            let uploadSocialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, URL: mediaURL, parameters: ["media": media])
            uploadSocialRequest.account = account
            session.dataTaskWithRequest(uploadSocialRequest.preparedURLRequest()) { (data, response, error) -> Void in
                if let data = data {
                    do {
                        let json: AnyObject = try NSJSONSerialization.JSONObjectWithData(data, options: [])
                        if let media_id = json["media_id_string"] as? String {
                            let parameters = ["status": status, "media_ids": media_id]
                            let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, URL: updateURL, parameters: parameters)
                            socialRequest.account = account
                            session.dataTaskWithRequest(socialRequest.preparedURLRequest()) { (data, response, error) -> Void in }.resume()
                        }
                    } catch let error as NSError {
                        NSLog("\(error.localizedDescription)")
                    }
                }
                }.resume()
        } else {
            let socialRequest = SLRequest(forServiceType: SLServiceTypeTwitter, requestMethod: .POST, URL: updateURL, parameters: ["status": status])
            socialRequest.account = account
            session.dataTaskWithRequest(socialRequest.preparedURLRequest()) { (data, response, error) -> Void in }.resume()
        }
    }

    func updateRemaining() {
        var count = textView.text.characters.count
        let s = textView.text as NSString
        let urlRegexp = try! NSRegularExpression(pattern: "https?://[0-9a-zA-Z/:%#\\$&\\?\\(\\)~\\.=\\+\\-]+", options: NSRegularExpressionOptions.CaseInsensitive)
        let matches = urlRegexp.matchesInString(textView.text, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: textView.text.utf16.count))
        for match in matches {
            let url = s.substringWithRange(match.rangeAtIndex(0)) as String
            let urlCount = url.hasPrefix("https") ? 23 : 22
            count = count + urlCount - url.characters.count
        }
        if hasImage {
            count = count + 23
        }
        self.charactersRemaining = 140 - count
        self.validateContent()
    }
    
    func encodeGoogleMusicURL(string: NSString) -> String {
        let range = string.rangeOfString("=")
        if range.location != NSNotFound {
            if let query = string.substringFromIndex(range.location + 1).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet()) {
                return string.substringToIndex(range.location + 1) + query
            }
        }
        return string as String
    }
    
    func titleGoogleMusicURL(string: NSString) -> String {
        let range = string.rangeOfString("=")
        if range.location != NSNotFound {
            return string.substringFromIndex(range.location + 1)
        }
        return ""
    }

    func loadGoogleMusicInfo() {
        if !contentText.hasPrefix("https://play.google.com/music/m/") {
            return
        }
        guard let musicURL = NSURL(string: encodeGoogleMusicURL(self.contentText)) else {
            return
        }
        let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
        let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
        session.dataTaskWithURL(musicURL) { (data, response, error) -> Void in
            guard let data = data else {
                return
            }
            if let html = NSString(data: data, encoding: NSUTF8StringEncoding) {
                let s = html as String
                let matches = self.regexp.matchesInString(s, options: NSMatchingOptions(rawValue: 0), range: NSRange(location: 0, length: s.utf16.count))
                for match in matches {
                    let type = html.substringWithRange(match.rangeAtIndex(1))
                    let content = html.substringWithRange(match.rangeAtIndex(2))
                    if type == "title" {
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            if content == "Listen on Google Play Music" {
                                self.textView.text = "#NowPlaying " + self.titleGoogleMusicURL(self.contentText) + "\n" + musicURL.absoluteString
                                self.textView.selectedRange = NSRange.init(location: 0, length: 0)
                                self.updateRemaining()
                            } else {
                                self.textView.text = "#NowPlaying " + content + "\n" + musicURL.absoluteString
                                self.textView.selectedRange = NSRange.init(location: 0, length: 0)
                                self.updateRemaining()
                            }
                        })
                    }
                    if type == "image" && !content.hasSuffix("play_music_headphones_logo.png") {
                        if let imageURL = NSURL(string: content) {
                            NSLog("\(content)")
                            session.dataTaskWithURL(imageURL) { (data, response, error) -> Void in
                                if let data = data {
                                    self.albumImageData = data
                                    let image = UIImage(data: data)
                                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                        self.hasImage = true
                                        self.previewView.image = image
                                        self.updateRemaining()
                                    })
                                }
                                }.resume()
                        }
                    }
                }
            }
            }.resume()
    }

    override func viewDidLoad() {
        previewView.clipsToBounds = true
        previewView.contentMode = .ScaleAspectFill
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.previewView.addConstraints([
                NSLayoutConstraint(item: self.previewView, attribute: .Width, relatedBy: .Equal, toItem: nil, attribute: .Width, multiplier: 1.0, constant: 60),
                NSLayoutConstraint(item: self.previewView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1.0, constant: 60)
                ])
        })
        previewView.userInteractionEnabled = true
        previewView.addGestureRecognizer(UITapGestureRecognizer.init(target: self, action: "removeImage"))
    }

    func loadURL() {
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
                if provider.hasItemConformingToTypeIdentifier("public.url") {
                    provider.loadItemForTypeIdentifier("public.url", options: nil, completionHandler: {
                        (item, error) in
                        guard let itemURL = item as? NSURL else {
                            return
                        }
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.textView.text = self.textView.text + " " + itemURL.absoluteString
                        })
                    })
                }
                for key in ["public.jpeg", "public.image"] {
                    if provider.hasItemConformingToTypeIdentifier(key) {
                        provider.loadItemForTypeIdentifier(key, options: nil, completionHandler: {
                            (item, error) in
                            switch item {
                            case let itemURL as NSURL:
                                let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
                                let session = NSURLSession(configuration: configuration, delegate: nil, delegateQueue: nil)
                                session.dataTaskWithURL(itemURL) { (data, response, error) -> Void in
                                    if let data = data {
                                        self.albumImageData = data
                                        let image = UIImage(data: data)
                                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                            self.hasImage = true
                                            self.previewView.image = image
                                            self.updateRemaining()
                                        })
                                    }
                                    }.resume()
                            case let itemImage as UIImage:
                                self.albumImageData = UIImagePNGRepresentation(itemImage)
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.hasImage = true
                                    self.previewView.image = itemImage
                                    self.updateRemaining()
                                })
                            case let itemData as NSData:
                                self.albumImageData = itemData
                                let image = UIImage(data: itemData)
                                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                    self.hasImage = true
                                    self.previewView.image = image
                                    self.updateRemaining()
                                })
                            default:
                                break
                            }
                        })
                    }
                }
            }
        }

        
    }

    override func loadPreviewView() -> UIView! {
        loadGoogleMusicInfo()
        loadURL()
        return previewView
    }

    override func configurationItems() -> [AnyObject]! {
        let twitter = SLComposeSheetConfigurationItem()
        twitter.title = "Account"
        twitter.tapHandler = {
            let accountStore = ACAccountStore()
            let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
            accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
                granted, error in
                
                if granted {
                    let twitterAccounts = accountStore.accountsWithAccountType(accountType) as? [ACAccount] ?? []
                    
                    if twitterAccounts.count == 0 {
                        self.showDialog("Error", message: "There are no Twitter accounts configured. You can add or create a Twitter account in Settings.")
                    } else {
                        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
                        actionSheet.addAction(UIAlertAction(
                            title: "Close",
                            style: .Cancel,
                            handler: { action in
                                actionSheet.dismissViewControllerAnimated(true, completion: nil)
                        }))
                        for twitterAccount in twitterAccounts {
                            let account = twitterAccount
                            actionSheet.addAction(UIAlertAction(
                                title: account.username,
                                style: .Default,
                                handler: { action in
                                    twitter.value = account.username
                                    self.account = account
                            }))
                        }
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            self.presentViewController(actionSheet, animated: true, completion: nil)
                        })
                    }
                } else {
                    self.showDialog("Error", message: "Twitter requires you to authorize Justaway for iOS to use your account.")
                }
            }
        }
        let accountStore = ACAccountStore()
        let accountType = accountStore.accountTypeWithAccountTypeIdentifier(ACAccountTypeIdentifierTwitter)
        accountStore.requestAccessToAccountsWithType(accountType, options: nil) {
            granted, error in
            if granted {
                let twitterAccounts = accountStore.accountsWithAccountType(accountType) as? [ACAccount] ?? []
                if twitterAccounts.count > 0 {
                    let account = twitterAccounts[0]
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        twitter.value = account.username
                    })
                    self.account = account
                }
            }
        }
        return [twitter]
    }

    func removeImage() {
        hasImage = false
        albumImageData = nil
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.previewView.image = nil
            self.previewView.removeFromSuperview()
            self.updateRemaining()
        })
    }

    func showDialog(title: String, message: String) {
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        actionSheet.addAction(UIAlertAction(
            title: "Close",
            style: .Cancel,
            handler: { action in
                actionSheet.dismissViewControllerAnimated(true, completion: nil)
        }))
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            self.presentViewController(actionSheet, animated: true, completion: nil)
        })
    }
}
