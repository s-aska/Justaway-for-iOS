#import <UIKit/UIKit.h>
#import "JFIButton.h"
#import "JFITabViewController.h"

@interface JFIMainViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, weak) IBOutlet JFIButton *streamingButton;
@property (nonatomic, weak) IBOutlet UIView *scrollWrapperView;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIView *editorView;
@property (nonatomic, weak) IBOutlet UITextView *editorTextView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *editorBottomConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *editorHeightConstraint;
@property (nonatomic, weak) IBOutlet JFIButton *postButton;
@property (nonatomic, weak) IBOutlet JFIButton *imageButton;
@property (nonatomic) UIView *contentView;
@property (nonatomic) NSMutableArray *views;
@property (nonatomic) NSMutableArray *viewControllers;
@property (nonatomic) UIActivityIndicatorView *indicator;

- (IBAction)changePageAction:(id)sender;
- (IBAction)streamingAction:(id)sender;
- (IBAction)accountAction:(id)sender;
- (IBAction)postAction:(id)sender;
- (IBAction)closeAction:(id)sender;
- (IBAction)imageAction:(id)sender;
- (IBAction)tweetAction:(id)sender;

- (void)showIndicator;
- (void)hideIndicator;

@end
