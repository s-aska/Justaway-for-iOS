#import <UIKit/UIKit.h>
#import "JFIButton.h"

@interface JFIImageViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic) NSDictionary *media;
@property (nonatomic) UIActivityIndicatorView *indicator;

- (IBAction)closeAction:(id)sender;
- (IBAction)saveAction:(id)sender;

@end
