#import <UIKit/UIKit.h>
#import "JFITimelineViewController.h"

@interface JFIMainViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *streamingStatusLabel;
@property (nonatomic, weak) IBOutlet UIView *scrollWrapperView;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *contentView;
@property (nonatomic) JFITimelineViewController *timeline;

- (IBAction)changePageAction:(id)sender;

- (IBAction)accountAction:(id)sender;
- (IBAction)postAction:(id)sender;

@end
