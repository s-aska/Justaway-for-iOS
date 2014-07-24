#import "JFIImageViewController.h"
#import "JFIHTTPImageOperation.h"
#import "UIImage+Processing.h"
#import <ISMemoryCache/ISMemoryCache.h>
#import "JFITheme.h"
#import "SVProgressHUD.h"

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
    
    UILongPressGestureRecognizer *longGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(showMenu:)];
    [self.scrollView addGestureRecognizer:longGesture];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(close)];
    tapGesture.numberOfTapsRequired = 1;
    [self.scrollView addGestureRecognizer:tapGesture];
    
    self.scrollView.delegate = self;
    self.scrollView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5]; // 透過黒背景
    self.scrollView.contentMode = UIViewContentModeScaleAspectFit; // アスペクト比固定（ピンチイン・ピンチアウト時のアスペクト比）
    self.imageView.contentMode = UIViewContentModeScaleAspectFit; // アスペクト比固定（何も指定しないとUIImageViewに合わせて伸長してしまう）
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.menuBottomConstraint.constant = -50.0f;
    
    JFITheme *theme = [JFITheme sharedTheme];
    self.toolbarView.backgroundColor = theme.menuBackgroundColor;
    
    // 消し損ねたインジケーターがないかチェック
    NSURL *url = [[NSURL alloc] initWithString:[[self.media valueForKey:@"media_url"] stringByAppendingString:@":large"]];
    UIImage *image = [[ISMemoryCache sharedCache] objectForKey:url];
    if (image) {
        self.imageView.image = image;
    } else {
        
        // インジケーター表示
        [SVProgressHUD show];
        
        self.imageView.image = nil;
        [JFIHTTPImageOperation loadURL:url
                           processType:ImageProcessTypeNone
                               handler:^(NSHTTPURLResponse *response, UIImage *image, NSError *error) {
                                   
                                   // インジケーター非表示
                                   [SVProgressHUD dismiss];
                                   
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

- (IBAction)saveAction:(id)sender
{
    // 読み込み前は無視
    if (self.imageView.image == nil) {
        return;
    }
    
    // 読み込み中・保存中は無視（連打対策）
    if ([SVProgressHUD isVisible]) {
        return;
    }
    [SVProgressHUD show];
    UIImageWriteToSavedPhotosAlbum(self.imageView.image, self, @selector(onCompleteSave:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)showMenu:(UILongPressGestureRecognizer *)sender
{
    if([sender state] == UIGestureRecognizerStateBegan){
        self.menuBottomConstraint.constant = 0.0f;
        [UIView animateWithDuration:0.1
                              delay:0
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
                             [self.view layoutIfNeeded];
                         }
                         completion:^(BOOL finished){}
         ];
    }
}

- (void)close
{
    self.imageView.image = nil;
    [SVProgressHUD dismiss];
    [self.view removeFromSuperview];
}

// 画像保存完了時のセレクタ
- (void)onCompleteSave:(UIImage *)screenImage didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    [self close];
    NSString *message = error ? @"Failure" : @"Success";
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle: @""
                                                    message: message
                                                   delegate: nil
                                          cancelButtonTitle: @"OK"
                                          otherButtonTitles: nil];
    [alert show];
}

@end
