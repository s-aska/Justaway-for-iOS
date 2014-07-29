#import "JFISettingsViewController.h"
#import "JFIAccountViewController.h"
#import "JFITheme.h"
#import "JFIConstants.h"
#import "JFIAppDelegate.h"
#import "LVDebounce.h"

@interface JFISettingsViewController ()

@end

static const NSTimeInterval animationDuration = .2;

@implementation JFISettingsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setTheme];
    
    [self.fontSizeSlider addTarget:self
                            action:@selector(fontSizeChanged)
                  forControlEvents:UIControlEventValueChanged];
    
    [self.fontSizeSlider addTarget:self
                            action:@selector(fontSizeApply)
                  forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchUpOutside];
    
    self.bottomConstraint.constant = -50;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // テーマ設定
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setTheme)
                                                 name:JFISetThemeNotification
                                               object:delegate];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.bottomConstraint.constant = 0;
    
    [UIView animateWithDuration:animationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        [self.view layoutIfNeeded];
    }
                     completion:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [super viewWillDisappear:animated];
}

- (void)setTheme
{
    JFITheme *theme = [JFITheme sharedTheme];
    [self.themeNameLabel setText:theme.name];
    [self.themeNameLabel setTextColor:theme.menuTextColor];
}

#pragma mark - UIButton

- (IBAction)closeAction:(id)sender
{
    void(^close)() = ^(){
        
        self.bottomConstraint.constant = -50;
        
        [UIView animateWithDuration:animationDuration
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{
            [self.view layoutIfNeeded];
        }
                         completion:^(BOOL finished){
            [self.view removeFromSuperview];
        }];
    };
    
    if (self.currenToolbarView != nil) {
        [self hideMenu:self.currenToolbarView completion:close];
    } else {
        close();
    }
}

- (IBAction)accountAction:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"JFIAccount" bundle:nil];
    JFIAccountViewController *accountViewController = [storyboard instantiateViewControllerWithIdentifier:@"JFIAccountViewController"];
    [self presentViewController:accountViewController animated:YES completion:nil];
}

- (IBAction)fontSizeAction:(id)sender
{
    [self showMenu:self.fontSizeToolbarView];
}

- (IBAction)themeAction:(id)sender
{
    [self showMenu:self.themeToolbarView];
    
    JFITheme *theme1 = JFITheme.new;
    [theme1 setDarkTheme];
    JFITheme *theme2 = JFITheme.new;
    [theme2 setLightTheme];
    JFITheme *theme3 = JFITheme.new;
    [theme3 setSolarizedDarkTheme];
    JFITheme *theme4 = JFITheme.new;
    [theme4 setSolarizedLightTheme];
    JFITheme *theme5 = JFITheme.new;
    [theme5 setMonokaiTheme];
    
    int count = 0;
    NSArray *themes = @[theme1, theme2, theme3, theme4, theme5];
    for (JFITheme *theme in themes) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(5 + (count * 45), 22, 40, 40)];
        view.backgroundColor = theme.mainBackgroundColor;
        view.tag = count;
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(selectTheme:)];
        tapGesture.numberOfTapsRequired = 1;
        [view addGestureRecognizer:tapGesture];
        
        [self.themeToolbarView addSubview:view];
        count++;
    }
}

- (void)selectTheme:(UITapGestureRecognizer *)sender
{
    JFITheme *theme = [JFITheme sharedTheme];
    switch (sender.view.tag) {
        case 0:
            [theme setDarkTheme];
            [[NSNotificationCenter defaultCenter] postNotificationName:JFISetThemeNotification
                                                                object:[[UIApplication sharedApplication] delegate]
                                                              userInfo:nil];
            break;
            
        case 1:
            [theme setLightTheme];
            [[NSNotificationCenter defaultCenter] postNotificationName:JFISetThemeNotification
                                                                object:[[UIApplication sharedApplication] delegate]
                                                              userInfo:nil];
            break;
            
        case 2:
            [theme setSolarizedDarkTheme];
            [[NSNotificationCenter defaultCenter] postNotificationName:JFISetThemeNotification
                                                                object:[[UIApplication sharedApplication] delegate]
                                                              userInfo:nil];
            break;
            
        case 3:
            [theme setSolarizedLightTheme];
            [[NSNotificationCenter defaultCenter] postNotificationName:JFISetThemeNotification
                                                                object:[[UIApplication sharedApplication] delegate]
                                                              userInfo:nil];
            break;
            
        case 4:
            [theme setMonokaiTheme];
            [[NSNotificationCenter defaultCenter] postNotificationName:JFISetThemeNotification
                                                                object:[[UIApplication sharedApplication] delegate]
                                                              userInfo:nil];
            break;
            
        default:
            break;
    }
}

- (void)fontSizeChanged
{
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    if (delegate.fontSize == self.fontSizeSlider.value) {
        return;
    }
    NSLog(@"[%@] %s fontSize:%f", NSStringFromClass([self class]), sel_getName(_cmd), self.fontSizeSlider.value);
    delegate.fontSize = self.fontSizeSlider.value;
    delegate.resizing = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:JFISetFontSizeNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

- (void)fontSizeApply
{
    NSLog(@"[%@] %s fontSize:%f", NSStringFromClass([self class]), sel_getName(_cmd), self.fontSizeSlider.value);
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    delegate.resizing = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:JFIApplyFontSizeNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

- (void)hideMenu:(UIView *)menu completion:(void(^)())completion
{
    self.currenToolbarView = nil;
    
    [UIView animateWithDuration:animationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        menu.frame = CGRectMake(-menu.frame.size.width,
                                menu.frame.origin.y,
                                menu.frame.size.width,
                                menu.frame.size.height);
    }
                     completion:^(BOOL finished){
        menu.hidden = YES;
        if (completion) {
            completion();
        }
    }];
}

- (void)showMenu:(UIView *)menu
{
    if (self.currenToolbarView) {
        if (self.currenToolbarView == menu) {
            return;
        }
        [self hideMenu:self.currenToolbarView completion:nil];
    }
    self.currenToolbarView = menu;
    
    menu.frame = CGRectMake(menu.frame.size.width,
                            menu.frame.origin.y,
                            menu.frame.size.width,
                            menu.frame.size.height);
    menu.hidden = NO;
    
    [UIView animateWithDuration:animationDuration
                          delay:0
                        options:UIViewAnimationOptionCurveEaseInOut
                     animations:^{
        menu.frame = CGRectMake(0,
                                menu.frame.origin.y,
                                menu.frame.size.width,
                                menu.frame.size.height);
    }
                     completion:nil];
}

@end
