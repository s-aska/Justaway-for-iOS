#import <UIKit/UIKit.h>
#import "JFIHomeViewController.h"

@interface JFIMainViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton *streamingButton;
@property (nonatomic, weak) IBOutlet UIView *scrollWrapperView;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UITextField *editorTextField;
@property (nonatomic, weak) IBOutlet UIButton *postButton;
@property (nonatomic, weak) IBOutlet UIView *editorView;
@property (nonatomic) UIView *contentView;
@property (nonatomic) NSMutableArray *views;
@property (nonatomic) NSMutableArray *viewControllers;

- (IBAction)changePageAction:(id)sender;

- (IBAction)streamingAction:(id)sender;
- (IBAction)accountAction:(id)sender;
- (IBAction)postAction:(id)sender;
- (IBAction)tweetAction:(id)sender;

@end
