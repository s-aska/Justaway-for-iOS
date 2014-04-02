#import <UIKit/UIKit.h>

@interface JFIPostViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITextView *statusTextField;

- (IBAction)backAction:(id)sender;
- (IBAction)postAction:(id)sender;

@end
