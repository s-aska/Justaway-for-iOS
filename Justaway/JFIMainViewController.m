#import "JFIConstants.h"
#import "JFIAppDelegate.h"
#import "JFIMainViewController.h"
#import "JFIPostViewController.h"

@interface JFIMainViewController ()

@end

static const NSInteger JFIStreamingStatusLabelTag = 100;

@implementation JFIMainViewController

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        // Custom initialization
        NSLog(@"[JFIMainViewController] initWithCoder");
        self.title = @"Main";
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.contentView.frame = CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    NSLog(@"[JFIMainViewController] viewDidAppear scrollView width:%f", self.scrollView.frame.size.width);
    NSLog(@"[JFIMainViewController] viewDidAppear scrollWrapperView width:%f", self.scrollWrapperView.frame.size.width);
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"[JFIMainViewController] viewDidLoad");
    
    // 通知設定
    self.streamingStatusLabel.userInteractionEnabled = YES;
    self.streamingStatusLabel.tag = JFIStreamingStatusLabelTag;
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectStreamingHandler:)
                                                 name:JFIStreamingConnectNotification
                                               object:delegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(disconnectStreamingHandler:)
                                                 name:JFIStreamingDisconnectNotification
                                               object:delegate];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    NSLog(@"[JFIMainViewController] viewDidLayoutSubviews");
    
    //    self.scrollView.frame = self.view.bounds;
    self.scrollView.pagingEnabled = YES;
    self.scrollView.backgroundColor = [UIColor greenColor];
    //    self.contentView.backgroundColor = [UIColor blueColor];
    //    return;
    //    self.scrollView.translatesAutoresizingMaskIntoConstraints = YES;
    //    [self.scrollView setContentSize:CGSizeMake(self.view.frame.size.width, self.scrollView.frame.size.width)];
    
    //    self.scrollView.frame.size = CGSizeMake(self.view.frame.size.width, self.scrollView.frame.size.height);
    //    [self.scrollView setLayoutWidth:self.view.frame.size.width];
    //    self.scrollView.contentSize = CGSizeMake(width * 3, self.scrollView.frame.size.height);
    
    NSLog(@"[JFIMainViewController] scrollWrapperView width:%f", self.scrollWrapperView.frame.size.width);
    NSLog(@"[JFIMainViewController] scrollView width:%f", self.scrollView.frame.size.width);
    NSLog(@"[JFIMainViewController] scrollWrapperView height:%f", self.scrollWrapperView.frame.size.height);
    NSLog(@"[JFIMainViewController] scrollView height:%f", self.scrollView.frame.size.height);
    /*
     UIView *contentView = [[UIView alloc]
     initWithFrame:CGRectMake(0,0,self.scrollView.contentSize.width,self.scrollView.contentSize.height)];
     */
    // UIScrollViewに表示するコンテンツViewを作成する。
    //    CGSize s = CGSizeMake(self.view.frame.size.width, self.scrollView.frame.size.height);
    CGSize s = self.scrollWrapperView.frame.size;
    CGRect contentRect = CGRectMake(0, 0, s.width * 3, s.height);
    UIView *contentView = [[UIView alloc] initWithFrame:contentRect];
    //    UIView *contentView = self.contentView;
    
    // コンテンツViewに表示する緑色Viewを追加する。
    UIView *subContent1View = [[UIView alloc] initWithFrame:CGRectMake(s.width * 0, 0, s.width, s.height)];
    subContent1View.backgroundColor = [UIColor greenColor];
    
    self.timeline = [[JFITimelineViewController alloc] initWithNibName:@"JFITimelineViewController" bundle:nil];
    self.timeline.view.frame = self.scrollWrapperView.bounds;
    [subContent1View addSubview:self.timeline.view];
    [contentView addSubview:subContent1View];
    
    // コンテンツViewに表示する青色Viewを追加する。
    UIView *subContent2View = [[UIView alloc] initWithFrame:CGRectMake(s.width * 1, 0, s.width, s.height)];
    subContent2View.backgroundColor = [UIColor blueColor];
    [contentView addSubview:subContent2View];
    
    // コンテンツViewに表示する赤色Viewを追加する。
    UIView *subContent3View = [[UIView alloc] initWithFrame:CGRectMake(s.width * 2, 0, s.width, s.height)];
    subContent3View.backgroundColor = [UIColor redColor];
    [contentView addSubview:subContent3View];
    
    // スクロールViewにコンテンツViewを追加する。
    [self.scrollView addSubview:contentView];
    
    self.scrollView.contentSize = contentView.frame.size;
    
    self.scrollView.delegate = self;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    
    // 現在の表示位置（左上）のx座標とUIScrollViewの表示幅(320px)を
    // 用いて現在のページ番号を計算します。
    //    CGPoint offset = scrollView.contentOffset;
    //    int page = (offset.x + 160) / 320;
    
    //    NSLog(@"[JFIMainViewController] scrollViewDidScroll page:%i", page);
    
    // 現在表示しているページ番号と異なる場合には、
    // ページ切り替わりと判断し、処理を呼び出します。
    // currentPageは、現在ページ数を保持するフィールド変数。
    //    if (currentPage != page) {
    //        doSomethingWhenPagingOccurred();
    //        currentPage = page;
    //    }
}

#pragma mark - Action

- (IBAction)changePageAction:(id)sender
{
    [UIView animateWithDuration:.3
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
                         [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width * [sender tag], 0) animated:NO];
                     } completion:nil];
}

- (IBAction)postAction:(id)sender
{
    NSLog(@"[JFIMainViewController] postAction");
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    if ([delegate.accounts count] > 0) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"JFIPost" bundle:nil];
        JFIPostViewController *postViewController = [storyboard instantiateViewControllerWithIdentifier:@"JFIPostViewController"];
        [self.navigationController pushViewController:postViewController animated:YES];
    } else {
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"error"
                              message:@"「認」ボタンからアカウントを追加して下さい。"
                              delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
    }
}

- (IBAction)accountAction:(id)sender
{
    NSLog(@"[JFIMainViewController] accountAction");
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"JFIAccount" bundle:nil];
    JFIPostViewController *accountViewController = [storyboard instantiateViewControllerWithIdentifier:@"JFIAccountViewController"];
    [self presentViewController:accountViewController animated:YES completion:nil];
}

#pragma mark - UIViewController

-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    return;
    UITouch *touch = [[event allTouches] anyObject];
    if (touch.view.tag == self.streamingStatusLabel.tag) {
        JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
        if (delegate.onlineStreaming) {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"connect"
                                  message:@"ストリーミングを終了します"
                                  delegate:nil
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
            [delegate stopStreaming];
        } else {
            UIAlertView *alert = [[UIAlertView alloc]
                                  initWithTitle:@"connect"
                                  message:@"ストリーミングを開始します"
                                  delegate:nil
                                  cancelButtonTitle:nil
                                  otherButtonTitles:@"OK", nil
                                  ];
            [alert show];
            [delegate startStreaming];
        }
    }
}

#pragma mark - NSNotificationCenter handler

- (void)connectStreamingHandler:(NSNotification *)center
{
    self.streamingStatusLabel.text = @"( ◠‿◠ )";
}

- (void)disconnectStreamingHandler:(NSNotification *)center
{
    self.streamingStatusLabel.text = @"(◞‸◟)";
}

@end
