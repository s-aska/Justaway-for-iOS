#import <UIKit/UIKit.h>
#import "JFIHomeViewController.h"

@interface JFIMainViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate>

@property (nonatomic, weak) IBOutlet UIButton *streamingButton;
@property (nonatomic, weak) IBOutlet UIView *scrollWrapperView;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *editorView;
@property (nonatomic, weak) IBOutlet UITextView *editorTextView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *editorBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *editorHeightConstraint;
@property (nonatomic, weak) IBOutlet UIButton *postButton;
@property (nonatomic) UIView *contentView;
@property (nonatomic) NSMutableArray *views;
@property (nonatomic) NSMutableArray *viewControllers;

- (IBAction)changePageAction:(id)sender;

- (IBAction)streamingAction:(id)sender;
- (IBAction)accountAction:(id)sender;
- (IBAction)postAction:(id)sender;
- (IBAction)closeAction:(id)sender;
- (IBAction)tweetAction:(id)sender;

@end
