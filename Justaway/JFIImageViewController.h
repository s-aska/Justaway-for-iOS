#import <UIKit/UIKit.h>

@interface JFIImageViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, weak) IBOutlet UIScrollView *scrollView;
@property (nonatomic, weak) IBOutlet UIImageView *imageView;
@property (nonatomic) NSDictionary *media;

@end
