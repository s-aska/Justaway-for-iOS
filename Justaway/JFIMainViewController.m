#import "JFIConstants.h"
#import "JFIAppDelegate.h"
#import "JFIMainViewController.h"
#import "JFIPostViewController.h"
#import "JFINotificationsViewController.h"
#import "JFIMessagesViewController.h"

@interface JFIMainViewController ()

@property (nonatomic) int currentPage;

@end

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

- (void)viewDidAppear:(BOOL)animated
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
    
    self.viewControllers = NSMutableArray.new;
    self.views = NSMutableArray.new;
    
    // 通知設定
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
    NSLog(@"[JFIMainViewController] scrollWrapperView width:%f height:%f", self.scrollWrapperView.frame.size.width, self.scrollWrapperView.frame.size.height);
    NSLog(@"[JFIMainViewController] scrollView width:%f height:%f", self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    
    // UIScrollViewに表示するコンテンツViewを作成する。
    CGSize s = self.scrollWrapperView.frame.size;
    if ([self.views count] > 0) {
        NSInteger index = 0;
        for (UIView *view in self.views) {
            view.frame = CGRectMake(s.width * index, 0, s.width, s.height);
            index++;
        }
        self.scrollView.contentSize = CGSizeMake(s.width * index, s.height);
        self.contentView.frame = CGRectMake(0, 0, s.width * index, s.height);
        return;
    }
    
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, s.width * 3, s.height)];
    
    JFIHomeViewController *homeViewController = [[JFIHomeViewController alloc]
                                                 initWithNibName:NSStringFromClass([JFIHomeViewController class]) bundle:nil];
    homeViewController.view.frame = CGRectMake(s.width * 0, 0, s.width, s.height);
    UIView *homeView = [[UIView alloc] initWithFrame:CGRectMake(s.width * 0, 0, s.width, s.height)];
    [homeView addSubview:homeViewController.view];
    [self.contentView addSubview:homeView];
    [self.viewControllers addObject:homeViewController];
    [self.views addObject:homeView];
    
    JFINotificationsViewController *notificationsViewController = [[JFINotificationsViewController alloc]
                                                                   initWithNibName:NSStringFromClass([JFINotificationsViewController class]) bundle:nil];
    notificationsViewController.view.frame = CGRectMake(0, 0, s.width, s.height);
    UIView *notificationsView = [[UIView alloc] initWithFrame:CGRectMake(s.width * 1, 0, s.width, s.height)];
    [notificationsView addSubview:notificationsViewController.view];
    [self.contentView addSubview:notificationsView];
    [self.viewControllers addObject:notificationsViewController];
    [self.views addObject:notificationsView];
    
    JFIMessagesViewController *messagesViewController = [[JFIMessagesViewController alloc]
                                                         initWithNibName:NSStringFromClass([JFIMessagesViewController class]) bundle:nil];
    messagesViewController.view.frame = CGRectMake(0, 0, s.width, s.height);
    UIView *messagesView = [[UIView alloc] initWithFrame:CGRectMake(s.width * 2, 0, s.width, s.height)];
    [messagesView addSubview:messagesViewController.view];
    [self.contentView addSubview:messagesView];
    [self.viewControllers addObject:messagesViewController];
    [self.views addObject:messagesView];
    
    [self.scrollView addSubview:self.contentView];
    
    self.scrollView.contentSize = self.contentView.frame.size;
    self.scrollView.delegate = self;
    self.scrollView.pagingEnabled = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGPoint offset = scrollView.contentOffset;
    int page = (offset.x + 160) / 320;
    
    if (self.currentPage != page) {
        self.currentPage = page;
    }
}

#pragma mark - Action

- (IBAction)changePageAction:(id)sender
{
    if (self.currentPage == [sender tag]) {
        JFIDiningViewController *viewController = (JFIDiningViewController *) self.viewControllers[self.currentPage];
        [viewController.tableView setContentOffset:CGPointZero animated:YES];
    } else {
        [UIView animateWithDuration:.3
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [self.scrollView setContentOffset:CGPointMake(self.scrollView.frame.size.width * [sender tag], 0) animated:NO];
                         } completion:nil];
    }
}

- (IBAction)streamingAction:(id)sender
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    if (delegate.onlineStreaming) {
        /* TODO: Toast的な奴で置き換える
        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:@"connect"
                              message:@"ストリーミングを終了します"
                              delegate:nil
                              cancelButtonTitle:nil
                              otherButtonTitles:@"OK", nil
                              ];
        [alert show];
         */
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

#pragma mark - NSNotificationCenter handler

- (void)connectStreamingHandler:(NSNotification *)center
{
    NSLog(@"[JFIMainViewController] connectStreamingHandler");
    [self.streamingButton setTitle:@"( ◠‿◠ )" forState:UIControlStateNormal];
}

- (void)disconnectStreamingHandler:(NSNotification *)center
{
    NSLog(@"[JFIMainViewController] disconnectStreamingHandler");
    [self.streamingButton setTitle:@"(◞‸◟)" forState:UIControlStateNormal];
}

@end
