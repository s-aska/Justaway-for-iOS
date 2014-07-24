#import <UIKit/UIKit.h>
#import "JFIButton.h"

@interface JFIImageViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *menuBottomConstraint;
@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic, weak) IBOutlet UIView *toolbarView;
@property (nonatomic) NSDictionary *media;

- (IBAction)saveAction:(id)sender;

@end
