import UIKit
import EventBox
import QBImagePicker

class EditorViewController: UIViewController, QBImagePickerControllerDelegate {
    
    // MARK: Properties
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var containerViewButtomConstraint: NSLayoutConstraint! // Used to adjust the height when the keyboard hides and shows.
    
    @IBOutlet weak var textView: AutoExpandTextView!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint! // Used to AutoExpandTextView
    
    var imagePickerController = QBImagePickerController.new()
    
    @IBOutlet weak var imageContainerView: BackgroundScrollView!
    @IBOutlet weak var imageContainerHeightConstraint: NSLayoutConstraint!
    
    var images :[NSData] = []
    
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
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        EventBox.off(self)
    }
    
    // MARK: - Configuration
    
    func configureView() {
        textView.configure(heightConstraint: textViewHeightConstraint)
        imageContainerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "image"))
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
        imagePickerController = QBImagePickerController.new() // reset
        imagePickerController.delegate = self
        imagePickerController.allowsMultipleSelection = true
        imagePickerController.minimumNumberOfSelection = 0
        imagePickerController.maximumNumberOfSelection = 4
        imagePickerController.showsNumberOfSelectedAssets = true
        imagePickerController.mediaType = QBImagePickerMediaType.Image
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
            if self.view.hidden == true {
                self.view.hidden = false
            }
        } else {
            containerViewButtomConstraint.constant = 0
        }
        
        self.view.setNeedsUpdateConstraints()
        
        UIView.animateWithDuration(animationDuration, delay: 0, options: .BeginFromCurrentState, animations: {
            self.containerView.alpha = showsKeyboard ? 1 : 0
            self.view.layoutIfNeeded()
        }, completion: { finished in
            if !showsKeyboard {
                self.view.hidden = true
            }
        })
    }
    
    // MARK: - QBImagePickerControllerDelegate
    
    func qb_imagePickerController(imagePickerController: QBImagePickerController!, didFinishPickingAssets assets: [AnyObject]!) {
        images = []
        if assets.count > 0 {
            for view in imageContainerView.subviews {
                view.removeFromSuperview()
            }
            var i = 0
            let contentView = UIView(frame: CGRectMake(0, 0, 100 * CGFloat(assets.count), 120))
            for asset in assets {
                if let phasset = asset as? PHAsset {
                    PHImageManager.defaultManager().requestImageDataForAsset(phasset, options: nil, resultHandler: {
                        (imageData: NSData!, dataUTI: String!, orientation: UIImageOrientation, info: [NSObject : AnyObject]!) -> Void in
                        if let fileUrl = info["PHImageFileURLKey"] as? NSURL {
                            self.images.append(imageData)
                            let imageView = UIImageView(frame: CGRectMake(100 * CGFloat(i) + 10, 10, 90, 100))
                            imageView.clipsToBounds = true
                            imageView.contentMode = .ScaleAspectFill
                            imageView.image = UIImage(data: imageData)
                            contentView.addSubview(imageView)
                            i++
                        }
                    })
                }
            }
            imageContainerView.addSubview(contentView)
            imageContainerView.contentSize = contentView.frame.size
            imageContainerHeightConstraint.constant = 120
        } else {
            imageContainerHeightConstraint.constant = 0
        }
        imagePickerController.dismissViewControllerAnimated(true, completion: nil)
        show()
    }
    
    func qb_imagePickerControllerDidCancel(imagePickerController: QBImagePickerController!) {
        imagePickerController.dismissViewControllerAnimated(true, completion: nil)
        show()
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
    
    func image() {
        self.view.window?.rootViewController?.presentViewController(imagePickerController, animated: true, completion: nil)
    }
    
    func show() {
        view.hidden = false
        textView.becomeFirstResponder()
    }
    
    func hide() {
        inReplyToStatusId = nil
        textView.reset()
        resetPickerController()
        
        if (textView.isFirstResponder()) {
            textView.resignFirstResponder()
        } else {
            view.hidden = true
        }
    }
    
}
