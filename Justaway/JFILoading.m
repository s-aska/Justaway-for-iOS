#import "JFILoading.h"
#import "JFITheme.h"

@implementation JFILoading

- (id)initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyle)style
{
    self = [super initWithActivityIndicatorStyle:style];
    if (self) {
        self.hidesWhenStopped = YES;
    }
    return self;
}

+ (JFILoading *)sharedLoading
{
    static JFILoading *loading;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loading = [[JFILoading alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    });
    return loading;
}

- (void)startAnimating
{
    JFITheme *theme = [JFITheme sharedTheme];
    self.color = theme.titleTextColor;
    
    UIWindow *window = [UIApplication sharedApplication].keyWindow;
    self.center = window.rootViewController.view.center;
    [window.rootViewController.view addSubview:self];
    
    [super startAnimating];
}

@end
