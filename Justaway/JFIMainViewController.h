#import <UIKit/UIKit.h>
#import "JFIHomeViewController.h"

@interface JFIMainViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UILabel *streamingStatusLabel;
@property (nonatomic, weak) IBOutlet UIView *scrollWrapperView;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic) UIView *contentView;
@property (nonatomic) NSMutableArray *views;
@property (nonatomic) NSMutableArray *viewControllers;

- (IBAction)changePageAction:(id)sender;

- (IBAction)accountAction:(id)sender;
- (IBAction)postAction:(id)sender;

@end
