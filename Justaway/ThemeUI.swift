//
//  ThemeUI.swift
//  Justaway
//
//  Created by Shinichiro Aska on 1/9/15.
//  Copyright (c) 2015 Shinichiro Aska. All rights reserved.
//

import UIKit
import AVFoundation
import EventBox
import Async

// MARK: - ContainerView

class MenuView: UIView {}
class MenuShadowView: MenuView {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: -2.0)
        self.layer.shadowOpacity = ThemeController.currentTheme.shadowOpacity()
        self.layer.shadowRadius = 1.0
    }
}
class SideMenuShadowView: MenuShadowView {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 2.0, height: 0)
        self.layer.shadowOpacity = ThemeController.currentTheme.shadowOpacity()
        self.layer.shadowRadius = 1.0
    }
}
class SideMenuSeparator: UIView {}
class NavigationShadowView: MenuView {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: 2.0)
        self.layer.shadowOpacity = ThemeController.currentTheme.shadowOpacity()
        self.layer.shadowRadius = 1.0
    }
}
class BackgroundView: UIView {}
class BackgroundShadowView: BackgroundView {
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.shadowColor = UIColor.black.cgColor
        self.layer.shadowOffset = CGSize(width: 0, height: -2.0)
        self.layer.shadowOpacity = ThemeController.currentTheme.shadowOpacity()
        self.layer.shadowRadius = 1.0
    }
}
class BackgroundTableView: UITableView {}
class BackgroundTableViewCell: UITableViewCell {}
class BackgroundScrollView: UIScrollView {}
class CurrentTabMaskView: UIView {}
class QuotedStatusContainerView: UIView {
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderColor = ThemeController.currentTheme.cellSeparatorColor().cgColor
        layer.borderWidth = (1.0 / UIScreen.main.scale) / 1
    }
}
class ShowMoreTweetBackgroundView: UIView {}
class ShowMoreTweetLabel: UILabel {}
class ShowMoreTweetIndicatorView: UIActivityIndicatorView {}

// MARK: - Buttons

class StreamingButton: UIButton {
    var connectedColor = UIColor.green
    var normalColor = UIColor.gray
    var errorColor = UIColor.red

    override func awakeFromNib() {
        super.awakeFromNib()
        normalColor = ThemeController.currentTheme.bodyTextColor()
        connectedColor = ThemeController.currentTheme.streamingConnected()
        errorColor = ThemeController.currentTheme.streamingError()
        EventBox.onMainThread(self, name: Twitter.Event.StreamingStatusChanged.Name()) { _ in
            self.setTitleColor()
        }
        setTitleColor()
    }

    func setTitleColor() {
        switch Twitter.connectionStatus {
        case .connected:
            setTitleColor(connectedColor, for: UIControlState())
        case .connecting:
            setTitleColor(normalColor, for: UIControlState())
        case .disconnected:
            if Twitter.enableStreaming {
                setTitleColor(errorColor, for: UIControlState())
            } else {
                setTitleColor(normalColor, for: UIControlState())
            }
        case .disconnecting:
            setTitleColor(normalColor, for: UIControlState())
        }
    }

    deinit {
        EventBox.off(self)
    }
}
class MenuButton: BaseButton {}
class TabButton: BaseButton {
    var streaming = false {
        didSet {
            if streaming {
                setTitleColor(ThemeController.currentTheme.streamingConnected(), for: UIControlState())
            } else {
                setTitleColor(ThemeController.currentTheme.menuTextColor(), for: UIControlState())
            }
        }
    }
}
class FavoritesButton: BaseButton {}
class ReplyButton: BaseButton {}
class RetweetButton: BaseButton {}
class FollowButton: BaseButton {}
class UnfollowButton: BaseButton {
    override func awakeFromNib() {
        super.awakeFromNib()
        layerColor = ThemeController.currentTheme.followButtonSelected()
        borderColor = ThemeController.currentTheme.followButtonSelected()
    }
}

// MARK: - Lable

class TextLable: UILabel {}
class MenuLable: UILabel {}
class DisplayNameLable: UILabel {}
class ScreenNameLable: UILabel {}
class RelativeDateLable: UILabel {}
class AbsoluteDateLable: UILabel {}
class ClientNameLable: UILabel {}
class StatusLable: UITextView {
    var status: TwitterStatus?
    var message: TwitterMessage?
    var threadMode = false
    var links = [Link]()
    let playerView = AVPlayerView()

    struct Link {
        let entity: Entity
        let range: NSRange
        init(entity: Entity, range: NSRange) {
            self.entity = entity
            self.range = range
        }
    }

    enum Entity {
        case url(TwitterURL)
        case media(TwitterMedia)
        case hashtag(TwitterHashtag)
        case user(TwitterUser)
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        textContainer.lineFragmentPadding = 0
        textContainerInset = UIEdgeInsets.zero
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(StatusLable.touchesText(_:))))
    }

    // Disable text selection
    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.isKind(of: UILongPressGestureRecognizer.self) {
            gestureRecognizer.isEnabled = false
        }
        super.addGestureRecognizer(gestureRecognizer)
    }

    func setStatus(_ status: TwitterStatus) {
        self.status = status
        self.text = status.text
        var newlinks = [Link]()
        for url in status.urls {
            for result in findString(url.displayURL) {
                let link = Link(entity: Entity.url(url), range: result.range)
                newlinks.append(link)
            }
        }
        for media in status.media {
            for result in findString(media.displayURL) {
                let link = Link(entity: Entity.media(media), range: result.range)
                newlinks.append(link)
            }
        }
        for hashtag in status.hashtags {
            for result in findString("#" + hashtag.text) {
                let link = Link(entity: Entity.hashtag(hashtag), range: result.range)
                newlinks.append(link)
            }
        }
        for mention in status.mentions {
            for result in findString("@" + mention.screenName) {
                let link = Link(entity: Entity.user(mention), range: result.range)
                newlinks.append(link)
            }
        }
        links = newlinks
        setAttributes()
    }

    func setMessage(_ message: TwitterMessage, threadMode: Bool) {
        self.threadMode = threadMode
        self.message = message
        self.text = message.text
        var newlinks = [Link]()
        for url in message.urls {
            for result in findString(url.displayURL) {
                let link = Link(entity: Entity.url(url), range: result.range)
                newlinks.append(link)
            }
        }
        for media in message.media {
            for result in findString(media.displayURL) {
                let link = Link(entity: Entity.media(media), range: result.range)
                newlinks.append(link)
            }
        }
        for hashtag in message.hashtags {
            for result in findString("#" + hashtag.text) {
                let link = Link(entity: Entity.hashtag(hashtag), range: result.range)
                newlinks.append(link)
            }
        }
        for mention in message.mentions {
            for result in findString("@" + mention.screenName) {
                let link = Link(entity: Entity.user(mention), range: result.range)
                newlinks.append(link)
            }
        }
        links = newlinks
        setAttributes()
    }

    func setAttributes() {
        backgroundColor = ThemeController.currentTheme.mainBackgroundColor()
        let attributedText = NSMutableAttributedString(string: text)
        attributedText.addAttribute(NSForegroundColorAttributeName, value: ThemeController.currentTheme.bodyTextColor(), range: NSRange.init(location: 0, length: text.utf16.count))
        if let font = font {
            attributedText.addAttribute(NSFontAttributeName, value: UIFont.systemFont(ofSize: font.pointSize), range: NSRange.init(location: 0, length: text.utf16.count))
        }
        for link in links {
            attributedText.addAttribute(NSForegroundColorAttributeName, value: ThemeController.currentTheme.menuSelectedTextColor(), range: link.range)
        }
        self.attributedText = attributedText
    }

    fileprivate func findString(_ string: String) -> [NSTextCheckingResult] {
        let pattern = NSRegularExpression.escapedPattern(for: string)
        // swiftlint:disable:next force_try
        let regexp = try! NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options(rawValue: 0))
        return regexp.matches(in: text, options: NSRegularExpression.MatchingOptions(rawValue: 0), range: NSRange.init(location: 0, length: text.utf16.count))
    }

    func touchesText(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        guard let position = closestPosition(to: location) else {
            return
        }
        let selectedPosition = offset(from: beginningOfDocument, to: position)
        for link in links {
            if NSLocationInRange(selectedPosition, link.range) {
                touchesLink(link)
                return
            }
        }
        if let status = status {
            if !status.isRoot {
                TweetsViewController.show(status)
            }
        } else if let message = message, let account = AccountSettingsStore.get()?.account() {
            if threadMode {
                if let messages = Twitter.messages[account.userID] {
                    let threadMessages = messages.filter({ $0.collocutor.userID == message.collocutor.userID })
                    Async.main {
                        MessagesViewController.show(message.collocutor, messages: threadMessages)
                    }
                }
            } else {
                Async.main {
                    DirectMessageAlert.show(account, message: message)
                }
            }
        }
    }

    func touchesLink(_ link: Link) {
        switch link.entity {
        case .url(let url):
            Safari.openURL(URL(string: url.expandedURL)!)
        case .media(let media):
            if !media.videoURL.isEmpty {
                if let videoURL = URL(string: media.videoURL) {
                    showVideo(videoURL)
                }
            } else {
                ImageViewController.show([media.mediaURL], initialPage: 0)
            }
        case .hashtag(let hashtag):
            SearchViewController.show("#" + hashtag.text)
        case .user(let user):
            ProfileViewController.show(user)
        }
    }

    func showVideo(_ videoURL: URL) {
        guard let view = UIApplication.shared.keyWindow else {
            return
        }
        playerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: view.frame.height)
        playerView.player = AVPlayer(url: videoURL)
        playerView.player?.actionAtItemEnd = AVPlayerActionAtItemEnd.none
        playerView.setVideoFillMode(AVLayerVideoGravityResizeAspect)
        view.addSubview(playerView)
        playerView.player?.play()
    }
}
