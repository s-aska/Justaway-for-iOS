import UIKit
import EventBox
import QBImagePicker

class EditorViewController: UIViewController, QBImagePickerControllerDelegate {
    
    struct Static {
        static let instance = EditorViewController()
    }
    
    // MARK: Properties
    
    @IBOutlet weak var replyToContainerView: BackgroundView!
    @IBOutlet weak var replyToIconImageView: UIImageView!
    @IBOutlet weak var replyToNameLabel: DisplayNameLable!
    @IBOutlet weak var replyToScreenNameLabel: ScreenNameLable!
    @IBOutlet weak var replyToStatusLabel: StatusLable!
    
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewButtomConstraint: NSLayoutConstraint! // Used to adjust the height when the keyboard hides and shows.
    
    @IBOutlet weak var textView: AutoExpandTextView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint! // Used to AutoExpandTextView
    
    @IBOutlet weak var imageContainerView: UIScrollView!
    @IBOutlet weak var imageContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageContentView: UIView!
    
    @IBOutlet weak var imageView1: UIImageView!
    @IBOutlet weak var imageView2: UIImageView!
    @IBOutlet weak var imageView3: UIImageView!
    @IBOutlet weak var imageView4: UIImageView!
    @IBOutlet weak var imageButton1: MenuButton!
    @IBOutlet weak var imageButton2: MenuButton!
    @IBOutlet weak var imageButton3: MenuButton!
    @IBOutlet weak var imageButton4: MenuButton!
    
    var images: [NSData] = []
    var imageViews: [UIImageView] = []
    var imageButtons: [MenuButton] = []
    var picking = false
    
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
        }
        imageButtons = [imageButton1, imageButton2, imageButton3, imageButton4]
        
        resetPickerController()
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
        for imageButton in imageButtons {
            imageButton.hidden = true
        }
        imageContainerHeightConstraint.constant = 0
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
            self.containerView.alpha = showsKeyboard ? 1 : 0
            self.view.layoutIfNeeded()
        }, completion: { finished in
            if !showsKeyboard {
                if !self.picking {
                    self.view.removeFromSuperview()
                }
            }
        })
    }
    
    // MARK: - QBImagePickerControllerDelegate
    
    func qb_imagePickerController(imagePickerController: QBImagePickerController!, didFinishPickingAssets assets: [AnyObject]!) {
        picking = false
        if assets.count > 0 {
            var i = images.count
            for asset in assets {
                if let phasset = asset as? PHAsset {
                    PHImageManager.defaultManager().requestImageDataForAsset(phasset, options: nil, resultHandler: {
                        (imageData: NSData?, dataUTI: String?, orientation: UIImageOrientation, info: [NSObject : AnyObject]?) -> Void in
                        if let imageData = imageData {
                            self.images.append(imageData)
                            self.imageViews[i].image = UIImage(data: imageData)
                            self.imageButtons[i].hidden = false
                            i++
                        }
                    })
                }
            }
            imageContainerHeightConstraint.constant = 110
        } else {
            imageContainerHeightConstraint.constant = 0
        }
        imagePickerController.dismissViewControllerAnimated(true, completion: nil)
        self.show()
    }
    
    func qb_imagePickerControllerDidCancel(imagePickerController: QBImagePickerController!) {
        picking = false
        imagePickerController.dismissViewControllerAnimated(true, completion: nil)
        self.show()
    }
    
    // MARK: - Actions
    
    @IBAction func hide(sender: UIButton) {
        hide()
    }
    
    @IBAction func image(sender: UIButton) {
        image()
    }
    
    @IBAction func send(sender: UIButton) {
        let text = textView.text
        if text.isEmpty && images.count == 0 {
            hide()
        } else {
            Twitter.statusUpdate(text, inReplyToStatusID: inReplyToStatusId, images: images, media_ids: [])
            hide()
        }
    }
    
    @IBAction func removeImage(sender: UIButton) {
        if images.count <= sender.tag {
            return
        }
        images.removeAtIndex(sender.tag)
        var i = 0
        for imageView in imageViews {
            if images.count > i {
                imageView.image = UIImage(data: images[i])
            } else {
                imageView.image = nil
                self.imageButtons[i].hidden = true
            }
            i++
        }
        if images.count == 0 {
            self.imageContainerHeightConstraint.constant = 0
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }
    }
    
    @IBAction func replyCancel(sender: UIButton) {
        inReplyToStatusId = nil
        replyToContainerView.hidden = true
        textView.text = textView.text.stringByReplacingOccurrencesOfString("^.*@[0-9a-zA-Z_]+ *", withString: "", options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
    }
    
    func image() {
        let capacity = UInt(4 - images.count)
        if capacity < 1 {
            ErrorAlert.show("You can select up to 4 images to tweet at once.")
            return;
        }
        picking = true
        let imagePickerController = QBImagePickerController.new()
        imagePickerController.delegate = self
        imagePickerController.allowsMultipleSelection = true
        imagePickerController.minimumNumberOfSelection = 0
        imagePickerController.maximumNumberOfSelection = capacity
        imagePickerController.showsNumberOfSelectedAssets = true
        imagePickerController.mediaType = QBImagePickerMediaType.Image
        self.view.window?.rootViewController?.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func show() {
        textView.becomeFirstResponder()
    }
    
    func hide() {
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
    
}
