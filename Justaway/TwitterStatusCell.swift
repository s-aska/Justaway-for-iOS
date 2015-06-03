import UIKit
import EventBox

let TwitterStatusCellImagePreviewHeight :CGFloat = 80
let TwitterStatusCellImagePreviewWidth :CGFloat = 240
let TwitterStatusCellImagePreviewPadding :CGFloat = 5

enum TwitterStatusCellLayout: String {
    case Normal = "Normal"
    case Actioned = "Actioned"
    case NormalWithImage = "NormalWithImage"
    case ActionedWithImage = "ActionedWithImage"
    
    static func fromStatus(status: TwitterStatus) -> TwitterStatusCellLayout {
        if status.isActioned {
            return status.media.count > 0 ? ActionedWithImage : Actioned
        } else {
            return status.media.count > 0 ? NormalWithImage : Normal
        }
    }
    
    static var allValues: [TwitterStatusCellLayout] {
        return [Normal, Actioned, NormalWithImage, ActionedWithImage]
    }
}

class TwitterStatusCell: BackgroundTableViewCell {

    // MARK: Properties
    var status: TwitterStatus?
    var layout: TwitterStatusCellLayout?
    
    @IBOutlet weak var iconImageView: UIImageView!
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var screenNameLabel: UILabel!
    @IBOutlet weak var protectedLabel: UILabel!
    @IBOutlet weak var relativeCreatedAtLabel: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    @IBOutlet weak var imagesContainerView: UIView!
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    
    @IBOutlet weak var imageView1HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView1WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView2HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView2WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView3HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView3WidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView4HeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageView4WidthConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var replyButton: UIButton!
    @IBOutlet weak var retweetButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!
    
    @IBOutlet weak var retweetCountLabel: UILabel!
    @IBOutlet weak var favoriteCountLabel: UILabel!
    @IBOutlet weak var viaLabel: UILabel!
    @IBOutlet weak var absoluteCreatedAtLabel: UILabel!
    
    @IBOutlet weak var actionedContainerView: UIView!
    @IBOutlet weak var actionedIconImageView: UIImageView!
    @IBOutlet weak var actionedTextLabel: UILabel!
    @IBOutlet weak var textHeightConstraint: NSLayoutConstraint!
    
    // MARK: - View Life Cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configureView()
        configureEvent()
    }
    
    deinit {
        EventBox.off(self)
    }
    
    // MARK: - Configuration
    
    func configureView() {
        selectionStyle = .None
        separatorInset = UIEdgeInsetsZero
        layoutMargins = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false
        
        for imageView in [imageView1, imageView2, imageView3, imageView4] {
            imageView.clipsToBounds = true
            imageView.contentMode = .ScaleAspectFill
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "showImage:"))
        }
    }
    
    func configureEvent() {
        EventBox.onMainThread(self, name: Twitter.Event.CreateFavorites.rawValue) { (n) -> Void in
            let statusID = n.object as! String
            if self.status?.statusID == statusID {
                self.favoriteButton.selected = true
                self.favoriteButton.transform = CGAffineTransformMakeScale(1, 1)
                let zoomOut = {
                    self.favoriteButton.transform = CGAffineTransformMakeScale(1, 1)
                }
                let zoomIn: (() -> Void) = {
                    self.favoriteButton.transform = CGAffineTransformMakeScale(1.4, 1.4)
                }
                let zoomInCompletion: ((Bool) -> Void) = { _ in
                    UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseIn, animations: zoomOut, completion: { _ in })
                }
                UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseIn, animations: zoomIn, completion: zoomInCompletion)
            }
        }
        
        EventBox.onMainThread(self, name: Twitter.Event.DestroyFavorites.rawValue) { (n) -> Void in
            let statusID = n.object as! String
            if self.status?.statusID == statusID {
                self.favoriteButton.selected = false
            }
        }
        
        EventBox.onMainThread(self, name: Twitter.Event.CreateRetweet.rawValue) { (n) -> Void in
            let statusID = n.object as! String
            if self.status?.statusID == statusID {
                self.retweetButton.selected = true
                self.retweetButton.transform = CGAffineTransformMakeScale(1, 1)
                let zoomOut = {
                    self.retweetButton.transform = CGAffineTransformMakeScale(1, 1)
                }
                let zoomIn: (() -> Void) = {
                    self.retweetButton.transform = CGAffineTransformMakeScale(1.4, 1.4)
                }
                let zoomInCompletion: ((Bool) -> Void) = { _ in
                    UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseIn, animations: zoomOut, completion: { _ in })
                }
                UIView.animateWithDuration(0.2, delay: 0, options: .CurveEaseIn, animations: zoomIn, completion: zoomInCompletion)
            }
        }
        
        EventBox.onMainThread(self, name: Twitter.Event.DestroyRetweet.rawValue) { (n) -> Void in
            let statusID = n.object as! String
            if self.status?.statusID == statusID {
                self.retweetButton.selected = false
            }
        }
        
        EventBox.onMainThread(self, name: EventFontSizePreview) { (n) -> Void in
            if let fontSize = n.userInfo?["fontSize"] as? NSNumber {
                self.statusLabel.font = UIFont.systemFontOfSize(CGFloat(fontSize.floatValue))
            }
        }
    }
    
    // MARK: - UITableViewCell
    
    
    
    // MARK: - Public Mehtods
    
    func setLayout(layout: TwitterStatusCellLayout) {
        if self.layout == nil || self.layout != layout {
            self.layout = layout
            if layout == .Normal || layout == .NormalWithImage {
                actionedContainerView.removeFromSuperview()
            }
            if layout == .Normal || layout == .Actioned {
                imagesContainerView.removeFromSuperview()
            }
            setNeedsLayout()
            layoutIfNeeded()
        }
    }
    
    func setText(status: TwitterStatus) {
        let numberFormatter = NSNumberFormatter()
        numberFormatter.numberStyle = .DecimalStyle
        
        Twitter.isFavorite(status.statusID) { isFavorite in
            if self.favoriteButton.selected != isFavorite {
                Async.main { self.favoriteButton.selected = isFavorite }
            }
        }
        
        Twitter.isRetweet(status.statusID) { retweetedStatusID in
            let isRetweet = retweetedStatusID != nil ? true : false
            if self.retweetButton.selected != isRetweet {
                Async.main { self.retweetButton.selected = isRetweet }
            }
        }
        
        iconImageView.image = nil
        nameLabel.text = status.user.name
        screenNameLabel.text = "@" + status.user.screenName
        protectedLabel.hidden = status.user.isProtected ? false : true
        statusLabel.text = status.text
        retweetCountLabel.text = status.retweetCount > 0 ? numberFormatter.stringFromNumber(status.retweetCount) : ""
        favoriteCountLabel.text = status.favoriteCount > 0 ? numberFormatter.stringFromNumber(status.favoriteCount) : ""
        relativeCreatedAtLabel.text = status.createdAt.relativeString
        absoluteCreatedAtLabel.text = status.createdAt.absoluteString
        viaLabel.text = status.via.name
        if let actionedBy = status.actionedBy {
            actionedTextLabel.text = "\(actionedBy.name) @\(actionedBy.screenName)"
            actionedIconImageView.image = nil
        }
        if status.media.count > 0 {
            imagesContainerView.hidden = true
            imageView1.image = nil
            imageView2.image = nil
            imageView3.image = nil
            imageView4.image = nil
        }
    }
    
    func setImage(status: TwitterStatus) {
        
        if iconImageView.image == nil {
            ImageLoaderClient.displayUserIcon(status.user.profileImageURL, imageView: iconImageView)
        }
        
        if let actionedBy = status.actionedBy {
            if actionedIconImageView.image == nil {
                ImageLoaderClient.displayActionedUserIcon(actionedBy.profileImageURL, imageView: actionedIconImageView)
            }
        }
        
        if status.media.count == 0 || imagesContainerView.hidden == false {
            return
        }
        
        imagesContainerView.hidden = false
        
        let fullHeight = imagesContainerView.frame.height
        let fullWidth = imagesContainerView.frame.width
        let harfHeight = (fullHeight - 5) / 2
        let halfWidth = (fullWidth - 5) / 2
        switch status.media.count {
        case 1:
            imageView1HeightConstraint.constant = fullHeight
            imageView1WidthConstraint.constant = fullWidth
            ImageLoaderClient.displayThumbnailImage(status.media[0].mediaThumbURL, imageView: imageView1)
            imageView1.hidden = false
            imageView2.hidden = true
            imageView3.hidden = true
            imageView4.hidden = true
        case 2:
            imageView1HeightConstraint.constant = fullHeight
            imageView1WidthConstraint.constant = halfWidth
            imageView3HeightConstraint.constant = fullHeight
            imageView3WidthConstraint.constant = halfWidth
            ImageLoaderClient.displayThumbnailImage(status.media[0].mediaThumbURL, imageView: imageView1)
            ImageLoaderClient.displayThumbnailImage(status.media[1].mediaThumbURL, imageView: imageView3)
            imageView1.hidden = false
            imageView2.hidden = true
            imageView3.hidden = false
            imageView4.hidden = true
        case 3:
            imageView1HeightConstraint.constant = fullHeight
            imageView1WidthConstraint.constant = halfWidth
            imageView3HeightConstraint.constant = harfHeight
            imageView3WidthConstraint.constant = halfWidth
            imageView4HeightConstraint.constant = harfHeight
            imageView4WidthConstraint.constant = halfWidth
            ImageLoaderClient.displayThumbnailImage(status.media[0].mediaThumbURL, imageView: imageView1)
            ImageLoaderClient.displayThumbnailImage(status.media[1].mediaThumbURL, imageView: imageView3)
            ImageLoaderClient.displayThumbnailImage(status.media[2].mediaThumbURL, imageView: imageView4)
            imageView1.hidden = false
            imageView2.hidden = true
            imageView3.hidden = false
            imageView4.hidden = false
        case 4:
            imageView1HeightConstraint.constant = harfHeight
            imageView1WidthConstraint.constant = halfWidth
            imageView2HeightConstraint.constant = harfHeight
            imageView2WidthConstraint.constant = halfWidth
            imageView3HeightConstraint.constant = harfHeight
            imageView3WidthConstraint.constant = halfWidth
            imageView4HeightConstraint.constant = harfHeight
            imageView4WidthConstraint.constant = halfWidth
            ImageLoaderClient.displayThumbnailImage(status.media[0].mediaThumbURL, imageView: imageView1)
            ImageLoaderClient.displayThumbnailImage(status.media[1].mediaThumbURL, imageView: imageView2)
            ImageLoaderClient.displayThumbnailImage(status.media[2].mediaThumbURL, imageView: imageView3)
            ImageLoaderClient.displayThumbnailImage(status.media[3].mediaThumbURL, imageView: imageView4)
            imageView1.hidden = false
            imageView2.hidden = false
            imageView3.hidden = false
            imageView4.hidden = false
        default:
            break
        }
    }
    
    // MARK: - Actions
    
    func showImage(sender: UIGestureRecognizer) {
        let tag = sender.view?.tag ?? 0
        if let status = self.status {
            ImageViewEvent(media: status.media, page: tag).post()
        }
    }
    
    @IBAction func reply(sender: UIButton) {
        if let status = self.status {
            Twitter.reply(status)
        }
    }
    
    @IBAction func retweet(sender: BaseButton) {
        if sender.lock() {
            if let statusID = self.status?.statusID {
                RetweetAlert.show(sender, statusID: statusID)
            }
        }
    }
    
    @IBAction func favorite(sender: BaseButton) {
        if sender.lock() {
            if let statusID = self.status?.statusID {
                Twitter.toggleFavorite(statusID)
            }
        }
    }
}
