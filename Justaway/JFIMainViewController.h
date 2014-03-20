#import <UIKit/UIKit.h>

@interface JFIMainViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

- (IBAction)timelineAction:(id)sender;
- (IBAction)notificationAction:(id)sender;
- (IBAction)directMessageAction:(id)sender;

- (IBAction)accountAction:(id)sender;
- (IBAction)postAction:(id)sender;

@end
