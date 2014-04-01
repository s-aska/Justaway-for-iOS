#import <UIKit/UIKit.h>

@interface JFIPostViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITextView *statusTextField;
@property (nonatomic, weak) IBOutlet UIButton *backButton;
@property (nonatomic, weak) IBOutlet UIButton *postButton;

- (IBAction)backAction:(id)sender;
- (IBAction)postAction:(id)sender;

@end
