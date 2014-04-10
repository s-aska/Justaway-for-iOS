#import "JFIConstants.h"
#import "JFIAppDelegate.h"
#import "JFIMainViewController.h"
#import "JFIPostViewController.h"
#import "JFINotificationsViewController.h"
#import "JFIMessagesViewController.h"

@interface JFIMainViewController ()

@property (nonatomic) int currentPage;
@property (nonatomic) int defaultEditorBottomConstraint;

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

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSLog(@"[JFIMainViewController] viewDidLoad");
    
    self.viewControllers = NSMutableArray.new;
    self.views = NSMutableArray.new;
    
    self.editorTextView.delegate = self;
    
    self.defaultEditorBottomConstraint = self.editorBottomConstraint.constant;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // Streamingの接続状況に応じて
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectStreamingHandler:)
                                                 name:JFIStreamingConnectNotification
                                               object:delegate];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(disconnectStreamingHandler:)
                                                 name:JFIStreamingDisconnectNotification
                                               object:delegate];
    
    // キーボードの開閉に応じて
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    // 背景をタップしたら、キーボードを隠す
    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                        action:@selector(closeSoftKeyboard)];
    [self.view addGestureRecognizer:gestureRecognizer];
    
    // 投稿ボタンをロングタップでクイックツイートモード
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                                   action:@selector(toggleEditorAction:)];
    [self.postButton addGestureRecognizer:longPressGesture];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.contentView.frame = CGRectMake(0, 0, self.scrollView.frame.size.width, self.scrollView.frame.size.height);
    NSLog(@"[JFIMainViewController] viewDidAppear scrollView width:%f", self.scrollView.frame.size.width);
    NSLog(@"[JFIMainViewController] viewDidAppear scrollWrapperView width:%f", self.scrollWrapperView.frame.size.width);
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

#pragma mark - UITextViewDelegate

- (void)textViewDidChange:(UITextView *)textView
{
    CGRect frame = textView.frame;
    CGFloat height = textView.contentSize.height > 34 ? textView.contentSize.height : 34;
    frame.size.height = height;
    textView.frame = frame;
    
    // これがないと下にめり込む
    self.editorHeightConstraint.constant = height;
}

#pragma mark - Action

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

- (IBAction)accountAction:(id)sender
{
    NSLog(@"[JFIMainViewController] accountAction");
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"JFIAccount" bundle:nil];
    JFIPostViewController *accountViewController = [storyboard instantiateViewControllerWithIdentifier:@"JFIAccountViewController"];
    [self presentViewController:accountViewController animated:YES completion:nil];
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

- (void)toggleEditorAction:(UILongPressGestureRecognizer *)sender
{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
            self.editorView.hidden = !self.editorView.hidden;
            break;
        case UIGestureRecognizerStateEnded:
            break;
        case UIGestureRecognizerStateChanged:
            break;
        case UIGestureRecognizerStateCancelled:
            break;
        case UIGestureRecognizerStatePossible:
            break;
        case UIGestureRecognizerStateFailed:
            break;
    }
}

- (IBAction)tweetAction:(id)sender
{
    NSLog(@"[JFIMainViewController] tweetAction");
    
    // TODO: 入力チェック
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // TODO: マルチアカウント対応
    STTwitterAPI *twitter = [delegate getTwitter];
    
    [twitter postStatusUpdate:[self.editorTextView text]
            inReplyToStatusID:nil
                     latitude:nil
                    longitude:nil
                      placeID:nil
           displayCoordinates:nil
                     trimUser:nil
                 successBlock:^(NSDictionary *status) {
                     [self.editorTextView setText:@""];
                 } errorBlock:^(NSError *error) {
                     NSLog(@"[JFIMainViewController] tweetAction error:%@", [error localizedDescription]);
                     [[[UIAlertView alloc]
                       initWithTitle:@"disconnect"
                       message:[error localizedDescription]
                       delegate:nil
                       cancelButtonTitle:nil
                       otherButtonTitles:@"OK", nil
                       ] show];
                 }];
}

#pragma mark -

- (void)closeSoftKeyboard {
    [self.view endEditing:YES];
}

#pragma mark - NSNotificationCenter handler

- (void)keyboardWillShow:(NSNotification *)notification
{
    CGRect keyboardRect = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    NSTimeInterval duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    self.editorBottomConstraint.constant = keyboardRect.size.height;
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSTimeInterval duration = [[[notification userInfo] objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    
    self.editorBottomConstraint.constant = self.defaultEditorBottomConstraint;
    
    [UIView animateWithDuration:duration animations:^{
        [self.view layoutIfNeeded];
    }];
}

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
