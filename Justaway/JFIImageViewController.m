#import "JFIImageViewController.h"
#import "JFIHTTPImageOperation.h"
#import "UIImage+Processing.h"
#import <ISMemoryCache/ISMemoryCache.h>
#import "JFITheme.h"

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
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeAction:)];
    tapGesture.numberOfTapsRequired = 1;
    [self.scrollView addGestureRecognizer:tapGesture];
    
    self.imageView.center = self.view.center;
    
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5]; // 透過黒背景
    self.scrollView.contentMode = UIViewContentModeScaleAspectFit; // アスペクト比固定（ピンチイン・ピンチアウト時のアスペクト比）
    self.imageView.contentMode = UIViewContentModeScaleAspectFit; // アスペクト比固定（何も指定しないとUIImageViewに合わせて伸長してしまう）
    
    self.indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.indicator.center = self.view.center;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    
    JFITheme *theme = [JFITheme sharedTheme];
    self.toolbarView.backgroundColor = theme.menuBackgroundColor;
    
    // 消し損ねたインジケーターがないかチェック
    [self.indicator removeFromSuperview];
    
    NSURL *url = [[NSURL alloc] initWithString:[[self.media valueForKey:@"media_url"] stringByAppendingString:@":large"]];
    
    // 画面に収まる最大スケールを計算
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    float w = [[self.media valueForKeyPath:@"sizes.large.w"] floatValue];
    float h = [[self.media valueForKeyPath:@"sizes.large.h"] floatValue];
    float scale_w = screenSize.width / w;
    float scale_h = screenSize.width / h;
    float scale = scale_w > scale_h ? scale_h : scale_w;
    
    self.scrollView.zoomScale = scale;
    
    UIImage *image = [[ISMemoryCache sharedCache] objectForKey:url];
    if (image) {
        self.imageView.image = image;
    } else {
        
        // インジケーター表示
        [self.view addSubview:self.indicator];
        [self.indicator startAnimating];
        
        self.imageView.image = nil;
        [JFIHTTPImageOperation loadURL:url
                           processType:ImageProcessTypeNone
                               handler:^(NSHTTPURLResponse *response, UIImage *image, NSError *error) {
                                   
                                   // インジケーター非表示
                                   [self.indicator stopAnimating];
                                   [self.indicator removeFromSuperview];
                                   
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

#pragma mark - UIButton

- (IBAction)closeAction:(id)sender
{
    self.imageView.image = nil;
    [self.indicator stopAnimating];
    [self.indicator removeFromSuperview];
    [self.view removeFromSuperview];
}

- (IBAction)saveAction:(id)sender
{
    // 読み込み前は無視
    if (self.imageView.image == nil) {
        return;
    }
    
    // 読み込み中・保存中は無視（連打対策）
    if ([self.indicator isAnimating]) {
        return;
    }
    [self.view addSubview:self.indicator];
    [self.indicator startAnimating];
    UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, @selector(onCompleteSave:didFinishSavingWithError:contextInfo:), NULL);
}

// 画像保存完了時のセレクタ
- (void)onCompleteSave:(UIImage *)screenImage didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    [self closeAction:nil];
    NSString *message = error ? @"Failure" : @"Success";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @""
                                                    message: message
                                                   delegate: nil
                                          cancelButtonTitle: @"OK"
                                          otherButtonTitles: nil];
    [alert show];
}

@end
