#import <UIKit/UIKit.h>
#import "JFIButton.h"
#import "JFITabViewController.h"
#import "JFIImageViewController.h"
#import "JFISettingsViewController.h"

@interface JFIMainViewController : UIViewController <UIScrollViewDelegate, UITextViewDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
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
@property (nonatomic) NSMutableArray *tabs;
@property (nonatomic) NSMutableArray *views;
@property (nonatomic) NSMutableArray *viewControllers;
@property (nonatomic) JFIImageViewController *imageViewController;
@property (nonatomic) JFISettingsViewController *settingsViewController;

- (IBAction)changePageAction:(id)sender;
- (IBAction)streamingAction:(id)sender;
- (IBAction)settingsAction:(id)sender;
- (IBAction)postAction:(id)sender;
- (IBAction)closeAction:(id)sender;
- (IBAction)imageAction:(id)sender;
- (IBAction)tweetAction:(id)sender;

@end
