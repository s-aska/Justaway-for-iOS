import UIKit
import EventBox
import Photos
import Async

class EditorViewController: UIViewController {
    
    struct Static {
        static let instance = EditorViewController()
    }
    
    // MARK: Properties
    
    @IBOutlet weak var replyToContainerView: BackgroundView!
    @IBOutlet weak var replyToIconImageView: UIImageView!
    @IBOutlet weak var replyToNameLabel: DisplayNameLable!
    @IBOutlet weak var replyToScreenNameLabel: ScreenNameLable!
    @IBOutlet weak var replyToStatusLabel: StatusLable!
    @IBOutlet weak var replyToStatusLabelHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var countLabel: MenuLable!
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewButtomConstraint: NSLayoutConstraint! // Used to adjust the height when the keyboard hides and shows.
    
    @IBOutlet weak var textView: AutoExpandTextView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint! // Used to AutoExpandTextView
    
    @IBOutlet weak var imageContainerView: UIScrollView!
    @IBOutlet weak var imageContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageContentView: UIView!
    @IBOutlet weak var collectionView: ImagePickerCollectionView!
    @IBOutlet weak var collectionHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var collectionMenuView: MenuView!
    
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    
    var images: [NSData] = []
    var imageViews: [UIImageView] = []
    var picking = false
    let imageContainerHeightConstraintDefault: CGFloat = 100
    
    override var nibName: String {
        return "EditorViewController"
    }
    
    var inReplyToStatusId: String?
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        configureEvent()
        Async.main {
            self.view.hidden = false
            self.show()
        }
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }
    
    // MARK: - Configuration
    
    func configureView() {
        view.hidden = true
        textView.configure(heightConstraint: textViewHeightConstraint)
        
        imageViews = [imageView1, imageView2, imageView3, imageView4]
        for imageView in imageViews {
            imageView.clipsToBounds = true
            imageView.contentMode = .ScaleAspectFill
            imageView.userInteractionEnabled = true
            imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "removeImage:"))
        }
        
        resetPickerController()
        
        let regexp = try! NSRegularExpression(pattern: "https?://[0-9a-zA-Z/:%#\\$&\\?\\(\\)~\\.=\\+\\-]+", options: NSRegularExpressionOptions.CaseInsensitive)
        textView.callback = {
            var count = self.textView.text.characters.count
            let s = self.textView.text as NSString
            let matches = regexp.matchesInString(self.textView.text, options: NSMatchingOptions(rawValue: 0), range: NSMakeRange(0, self.textView.text.utf16.count))
            for match in matches {
                let url = s.substringWithRange(match.rangeAtIndex(0)) as String
                let urlCount = url.hasPrefix("https") ? 23 : 22
                count = count + urlCount - url.characters.count
            }
            if self.images.count > 0 {
                count = count + 23
            }
            self.countLabel.text = String(140 - count)
        }
        
        collectionView.callback = { (asset: PHAsset) in
            let options = PHImageRequestOptions()
            options.deliveryMode = PHImageRequestOptionsDeliveryMode.HighQualityFormat
            options.synchronous = false
            options.networkAccessAllowed = true
            PHImageManager.defaultManager().requestImageDataForAsset(asset, options: options, resultHandler: {
                (imageData: NSData?, dataUTI: String?, orientation: UIImageOrientation, info: [NSObject : AnyObject]?) -> Void in
                if let imageData = imageData {
                    if self.images.count > 0 {
                        var i = 0
                        for image in self.images {
                            if imageData == image {
                                self.removeImageIndex(i)
                                return
                            }
                            i++
                        }
                    }
                    let i = self.images.count
                    if i >= 4 {
                        return
                    }
                    self.images.append(imageData)
                    self.imageViews[i].image = UIImage(data: imageData)
                    if self.imageContainerHeightConstraint.constant == 0 {
                        self.imageContainerHeightConstraint.constant = self.imageContainerHeightConstraintDefault
                        UIView.animateWithDuration(0.2, animations: { () -> Void in
                            self.view.layoutIfNeeded()
                        })
                    }
                }
            })
        }
    }
    
    func configureEvent() {
        EventBox.onMainThread(self, name: UIKeyboardWillShowNotification) { n in
            self.keyboardWillChangeFrame(n, showsKeyboard: true)
        }
        
        EventBox.onMainThread(self, name: UIKeyboardWillHideNotification) { n in
            self.keyboardWillChangeFrame(n, showsKeyboard: false)
        }
    }
    
    func resetPickerController() {
        images = []
        for imageView in imageViews {
            imageView.image = nil
        }
        collectionView.rows = []
        collectionHeightConstraint.constant = 0
        imageContainerHeightConstraint.constant = 0
        collectionMenuView.hidden = true
    }
    
    // MARK: - Keyboard Event Notifications
    
    func keyboardWillChangeFrame(notification: NSNotification, showsKeyboard: Bool) {
        let userInfo = notification.userInfo!
        let animationDuration: NSTimeInterval = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let keyboardScreenEndFrame = (userInfo[UIKeyboardFrameEndUserInfoKey]as! NSValue).CGRectValue()
        
        if showsKeyboard {
            let orientation: UIInterfaceOrientation = UIApplication.sharedApplication().statusBarOrientation
            if (orientation.isLandscape) {
                containerViewButtomConstraint.constant = keyboardScreenEndFrame.size.width
            } else {
                containerViewButtomConstraint.constant = keyboardScreenEndFrame.size.height
            }
            collectionHeightConstraint.constant = 0
            collectionMenuView.hidden = true
        } else {
            
            // en: UIKeyboardWillHideNotification occurs when you scroll through the conversion candidates in iOS9
            // ja: iOS9 では変換候補をスクロールする際 UIKeyboardWillHideNotification が発生する
            if !textView.text.isEmpty {
                return
            }
            containerViewButtomConstraint.constant = 0
        }
        
        self.view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(animationDuration, delay: 0, options: .BeginFromCurrentState, animations: {
            self.containerView.alpha = showsKeyboard || self.picking ? 1 : 0
            self.view.layoutIfNeeded()
        }, completion: { finished in
            if !showsKeyboard && !self.picking {
                self.view.removeFromSuperview()
            }
        })
    }
    
    // MARK: - Actions
    
    @IBAction func hide(sender: UIButton) {
        if picking {
            picking = false
            textView.becomeFirstResponder()
        } else {
            hide()
        }
    }
    
    @IBAction func image(sender: UIButton) {
        image()
    }
    
    @IBAction func voice(sender: UIButton) {
        if textView.text.hasSuffix(" #justaway") {
            return
        }
        let range = textView.selectedRange
        textView.text = textView.text + " #justaway"
        textView.selectedRange = range
    }
    
    @IBAction func send(sender: UIButton) {
        let text = textView.text
        if text.isEmpty && images.count == 0 {
            hide()
        } else {
            Twitter.statusUpdate(text, inReplyToStatusID: self.inReplyToStatusId, images: self.images, media_ids: [])
            hide()
        }
    }
    
    func removeImage(sender: UITapGestureRecognizer) {
        guard let index = sender.view?.tag else {
            return
        }
        if images.count <= index {
            return
        }
        removeImageIndex(index)
    }
    
    func removeImageIndex(index: Int) {
        images.removeAtIndex(index)
        var i = 0
        for imageView in imageViews {
            if images.count > i {
                imageView.image = UIImage(data: images[i])
            } else {
                imageView.image = nil
            }
            i++
        }
        if images.count == 0 {
            imageContainerHeightConstraint.constant = 0
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @IBAction func replyCancel(sender: UIButton) {
        if let inReplyToStatusId = inReplyToStatusId {
            let pattern = " ?https?://twitter\\.com/[0-9a-zA-Z_]+/status/\(inReplyToStatusId)"
            textView.text = textView.text.stringByReplacingOccurrencesOfString(pattern, withString: "", options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
        }
        inReplyToStatusId = nil
        replyToContainerView.hidden = true
        textView.text = textView.text.stringByReplacingOccurrencesOfString("^.*@[0-9a-zA-Z_]+ *", withString: "", options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
    }
    
    func image() {
        picking = true
        let height = UIApplication.sharedApplication().keyWindow?.frame.height ?? 480
        collectionHeightConstraint.constant = height - imageContainerHeightConstraintDefault - 10
        collectionMenuView.hidden = false
        textView.resignFirstResponder()
        if collectionView.rows.count == 0 {
            Async.background(block: { () -> Void in
                let options = PHFetchOptions()
                options.sortDescriptors = [
                    NSSortDescriptor(key: "creationDate", ascending: false)
                ]
                let assets: PHFetchResult = PHAsset.fetchAssetsWithMediaType(.Image, options: options)
                assets.enumerateObjectsUsingBlock { (asset, index, stop) -> Void in
                    self.collectionView.rows.append(asset as! PHAsset)
                }
                Async.main(block: { () -> Void in
                    self.collectionView.reloadData()
                })
            })
        }
    }
    
    func show() {
        textView.becomeFirstResponder()
        textView.callback?()
    }
    
    func hide() {
        picking = false
        inReplyToStatusId = nil
        replyToContainerView.hidden = true
        textView.reset()
        resetPickerController()
        
        if (textView.isFirstResponder()) {
            textView.resignFirstResponder()
        } else {
            view.removeFromSuperview()
        }
    }
    
    class func show(text: String? = nil, range: NSRange? = nil, inReplyToStatus: TwitterStatus? = nil) {
        if let vc = UIApplication.sharedApplication().keyWindow?.rootViewController {
            Static.instance.view.frame = CGRectMake(0, 0, vc.view.frame.width, vc.view.frame.height)
            Static.instance.resetPickerController()
            Static.instance.textView.text = text ?? ""
            if let inReplyToStatus = inReplyToStatus {
                Static.instance.inReplyToStatusId = inReplyToStatus.statusID
                Static.instance.replyToNameLabel.text = inReplyToStatus.user.name
                Static.instance.replyToScreenNameLabel.text = "@" + inReplyToStatus.user.screenName
                Static.instance.replyToStatusLabel.text = inReplyToStatus.text
                Static.instance.replyToStatusLabelHeightConstraint.constant =
                    measure(inReplyToStatus.text,
                        fontSize: Static.instance.replyToStatusLabel.font?.pointSize ?? 12,
                        wdith: Static.instance.replyToStatusLabel.frame.size.width)
                Static.instance.replyToContainerView.hidden = false
                ImageLoaderClient.displayUserIcon(inReplyToStatus.user.profileImageURL, imageView: Static.instance.replyToIconImageView)
            } else {
                Static.instance.inReplyToStatusId = nil
                Static.instance.replyToContainerView.hidden = true
            }
            if let selectedRange = range {
                Static.instance.textView.selectedRange = selectedRange
            }
            vc.view.addSubview(Static.instance.view)
        }
    }
    
    class func hide() {
        if Static.instance.textView == nil {
            return
        }
        Static.instance.hide()
    }
    
    class func measure(text: NSString, fontSize: CGFloat, wdith: CGFloat) -> CGFloat {
        return ceil(text.boundingRectWithSize(
            CGSizeMake(wdith, 0),
            options: NSStringDrawingOptions.UsesLineFragmentOrigin,
            attributes: [NSFontAttributeName: UIFont.systemFontOfSize(fontSize)],
            context: nil).size.height)
    }
}
