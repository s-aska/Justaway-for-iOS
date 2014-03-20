#import <UIKit/UIKit.h>

@interface JFIMainViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;

- (IBAction)changePageAction:(id)sender;

- (IBAction)accountAction:(id)sender;
- (IBAction)postAction:(id)sender;

@end
