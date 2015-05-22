import UIKit
import EventBox
import KeyClip

class FontSizeViewController: UIViewController {
    
    @IBOutlet weak var fontSizeSlider: UISlider!
    let actionSheet = UIAlertController()
    
    // MARK: Properties
    
    override var nibName: String {
        return "FontSizeViewController"
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    // MARK: - Configuration
    
    func configureView() {
        fontSizeSlider.addTarget(self, action: Selector("fontSizeChanged"), forControlEvents: UIControlEvents.ValueChanged)
        fontSizeSlider.addTarget(self, action: Selector("fontSizeFixed"), forControlEvents: UIControlEvents.TouchUpInside | UIControlEvents.TouchUpOutside)
        
        actionSheet.addAction(UIAlertAction(
            title: "Cancel",
            style: .Cancel,
            handler: { action in
                self.actionSheet.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        for size in Int(fontSizeSlider.minimumValue) ... Int(fontSizeSlider.maximumValue) {
            let fontSize = String(size)
            let title = fontSize + "pt"
            let style :UIAlertActionStyle = size == 12 ? .Destructive : .Default
            actionSheet.addAction(UIAlertAction(
                title: title,
                style: style,
                handler: { action in
                    self.fontSizeSlider.value = Float(size)
                    EventBox.post("fontSizeFixed", userInfo: ["fontSize": NSNumber(integer: size)])
                    KeyClip.save("fontSize", string: fontSize)
            }))
        }
        
        if let delegate = UIApplication.sharedApplication().delegate as? AppDelegate {
            fontSizeSlider.value = delegate.fontSize
        }
    }
    
    @IBAction func menuAction(sender: UIButton) {
        AlertController.showViewController(actionSheet)
    }
    
    // MARK: - Event
    
    func fontSizeChanged() {
        EventBox.post("fontSizeChanged", userInfo: ["fontSize": fontSizeSlider.value as NSNumber])
    }
    
    func fontSizeFixed() {
        EventBox.post("fontSizeFixed", userInfo: ["fontSize": fontSizeSlider.value as NSNumber])
    }
}
