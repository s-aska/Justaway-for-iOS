#import "JFIAppDelegate.h"
#import "JFIMainViewController.h"
#import "JFIPostViewController.h"

@interface JFIMainViewController ()

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
    // Do any additional setup after loading the view.
    NSLog(@"[JFIMainViewController] viewDidLoad");
    
    self.scrollView.pagingEnabled = YES;
    
    // UIScrollViewに表示するコンテンツViewを作成する。
    CGSize s = self.scrollView.frame.size;
    CGRect contentRect = CGRectMake(0, 0, s.width * 3, s.height);
    UIView *contentView = [[UIView alloc] initWithFrame:contentRect];
    
    // コンテンツViewに表示する緑色Viewを追加する。
    UIView *subContent1View = [[UIView alloc] initWithFrame:CGRectMake(320 * 0, 0, s.width, s.height)];
    //    subContent1View.backgroundColor = [UIColor greenColor];
    
    self.timeline = [[JFITimelineViewController alloc] initWithNibName:@"JFITimelineViewController" bundle:nil];
    [subContent1View addSubview:self.timeline.view];
    [contentView addSubview:subContent1View];
    
    // コンテンツViewに表示する青色Viewを追加する。
    UIView *subContent2View = [[UIView alloc] initWithFrame:CGRectMake(320 * 1, 0, s.width, s.height)];
    subContent2View.backgroundColor = [UIColor blueColor];
    [contentView addSubview:subContent2View];
    
    // コンテンツViewに表示する赤色Viewを追加する。
    UIView *subContent3View = [[UIView alloc] initWithFrame:CGRectMake(320 * 2, 0, s.width, s.height)];
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
                         [self.scrollView setContentOffset:CGPointMake(320 * [sender tag], 0) animated:NO];
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
                              initWithTitle:@"disconnect"
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

@end
