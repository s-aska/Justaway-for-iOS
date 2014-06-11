#import "JFIImageViewController.h"
#import "JFIHTTPImageOperation.h"
#import "UIImage+Processing.h"
#import <ISMemoryCache/ISMemoryCache.h>

@interface JFIImageViewController ()

@end

@implementation JFIImageViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // タップしたら消す
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self.view action:@selector(removeFromSuperview)];
    tapGesture.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:tapGesture];
    
    self.imageView.center = self.view.center;
    
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5]; // 透過黒背景
    self.scrollView.contentMode = UIViewContentModeScaleAspectFit; // 縦横比維持
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 消し損ねたインジケーターがないかチェック
    if ([self.view.subviews count] > 1) {
        [[self.view.subviews objectAtIndex:1] removeFromSuperview];
    }
    
    NSURL *url = [[NSURL alloc] initWithString:[[self.media valueForKey:@"media_url"] stringByAppendingString:@":large"]];
    
    // 画面に収まる最大スケールを計算
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    float scale_w = screenSize.width / [[self.media valueForKeyPath:@"sizes.large.w"] floatValue];
    float scale_h = screenSize.width / [[self.media valueForKeyPath:@"sizes.large.h"] floatValue];
    float scale = scale_w > scale_h ? scale_h : scale_w;
    
    self.scrollView.zoomScale = scale;
    
    UIImage *image = [[ISMemoryCache sharedCache] objectForKey:url];
    if (image) {
        self.imageView.image = image;
        [self.imageView sizeToFit];
    } else {
        
        // インジケーター表示
        UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
        indicator.center = self.view.center;
        [self.view addSubview:indicator];
        [indicator startAnimating];
        
        self.imageView.image = nil;
        [JFIHTTPImageOperation loadURL:url
                           processType:ImageProcessTypeNone
                               handler:^(NSHTTPURLResponse *response, UIImage *image, NSError *error) {
                                   
                                   // インジケーター非表示
                                   [indicator stopAnimating];
                                   [indicator removeFromSuperview];
                                   
                                   if (response) {
                                       
                                       // ネットワークからの読み込み時のみフェードイン
                                       self.imageView.alpha = 0;
                                       self.imageView.image = image;
                                       [UIView animateWithDuration:0.2
                                                             delay:0
                                                           options:UIViewAnimationOptionCurveEaseIn
                                                        animations:^{ self.imageView.alpha = 1; }
                                                        completion:^(BOOL finished){}
                                        ];
                                   } else {
                                       self.imageView.image = image;
                                   }
                                   
                                   [self.imageView sizeToFit];
                               }];
        
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    // ピンチイン・ピンチアウトで拡大・縮小させるUIView
    return self.imageView;
}

@end
