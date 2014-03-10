#import <UIKit/UIKit.h>

@interface JFISecondViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, weak) IBOutlet UIPickerView *accountsPickerView;
@property (nonatomic, weak) IBOutlet UITextView *statusTextField;

- (IBAction)loginInSafariAction:(id)sender;
- (IBAction)clearAction:(id)sender;
- (IBAction)postAction:(id)sender;

@end
