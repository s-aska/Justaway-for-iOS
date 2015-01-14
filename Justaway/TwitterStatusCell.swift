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

class TwitterStatusCell: UITableViewCell {

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
        
        selectionStyle = .None
        separatorInset = UIEdgeInsetsZero
        layoutMargins = UIEdgeInsetsZero
        preservesSuperviewLayoutMargins = false
        
        EventBox.onMainThread(self, name: Twitter.Event.CreateFavorites.rawValue) { (n) -> Void in
            let statusID = n.object as String
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
            let statusID = n.object as String
            if self.status?.statusID == statusID {
                self.favoriteButton.selected = false
            }
        }
    }
    
    deinit {
        EventBox.off(self)
    }
    
    // MARK: - UITableViewCell
    
    
    
    // MARK: - Public Mehtods
    
    func setLayout(layout: TwitterStatusCellLayout) {
        if self.layout == nil || self.layout != layout {
            self.layout = layout
            if layout == .Normal || layout == .NormalWithImage {
                self.actionedContainerView.removeFromSuperview()
            }
            if layout == .Normal || layout == .Actioned {
                self.imagesContainerView.removeFromSuperview()
            }
            self.setNeedsLayout()
            self.layoutIfNeeded()
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
        
        self.iconImageView.image = nil
        self.nameLabel.text = status.user.name
        self.screenNameLabel.text = "@" + status.user.screenName
        self.protectedLabel.hidden = status.isProtected ? false : true
        self.statusLabel.text = status.text
        self.retweetCountLabel.text = status.retweetCount > 0 ? numberFormatter.stringFromNumber(status.retweetCount) : ""
        self.favoriteCountLabel.text = status.favoriteCount > 0 ? numberFormatter.stringFromNumber(status.favoriteCount) : ""
        self.relativeCreatedAtLabel.text = status.createdAt.relativeString
        self.absoluteCreatedAtLabel.text = status.createdAt.absoluteString
        self.viaLabel.text = status.via.name
        if let actionedBy = status.actionedBy {
            self.actionedTextLabel.text = "@" + actionedBy.screenName
            self.actionedIconImageView.image = nil
        }
        if status.media.count > 0 {
            self.imagesContainerView.hidden = true
            self.imageView1.image = nil
            self.imageView2.image = nil
            self.imageView3.image = nil
        }
    }
    
    func setImage(status: TwitterStatus) {
        
        if status.media.count == 0 || self.imagesContainerView.hidden == false {
            return
        }
        
        self.imagesContainerView.hidden = false
        
        var i = 0
        let imageViews = [self.imageView1, self.imageView2, self.imageView3];
        for media in status.media {
            ImageLoaderClient.displayImage(media.mediaThumbURL, imageView: imageViews[i])
            NSLog("\(media.mediaThumbURL)")
            i++
            if i > 2 {
                break
            }
        }
    }
    
    // MARK: - Actions
    
    func showImage(sender: AnyObject) {
        
    }
    
    @IBAction func reply(sender: UIButton) {
        
    }
    
    @IBAction func retweet(sender: UIButton) {
        
    }
    
    @IBAction func favorite(sender: BaseButton) {
        if sender.lock() {
            if let statusID = self.status?.statusID {
                Twitter.toggleFavorite(statusID)
            }
        }
    }
    
}
