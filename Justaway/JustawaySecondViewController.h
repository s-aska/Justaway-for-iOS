#import <UIKit/UIKit.h>

@interface JustawaySecondViewController : UIViewController <UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet UIPickerView *accountsPickerView;
@property (weak, nonatomic) IBOutlet UITextView *statusTextField;

- (IBAction)loginInSafariAction:(id)sender;
- (IBAction)clearAction:(id)sender;
- (IBAction)postAction:(id)sender;

@end
