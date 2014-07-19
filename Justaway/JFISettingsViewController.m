#import "JFISettingsViewController.h"
#import "JFIAccountViewController.h"
#import "JFITheme.h"
#import "JFIConstants.h"
#import "JFIAppDelegate.h"

@interface JFISettingsViewController ()

@property (nonatomic) BOOL fontSizeApply;

@end

@implementation JFISettingsViewController

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
    
    [self setTheme];
    
    [self.fontSizeSlider addTarget:self
                            action:@selector(fontSizeChanged)
                  forControlEvents:UIControlEventValueChanged];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    
    // テーマ設定
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(setTheme)
                                                 name:JFISetThemeNotification
                                               object:delegate];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.fontSizeApply) {
        self.fontSizeApply = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:JFIApplyFontSizeNotification
                                                            object:[[UIApplication sharedApplication] delegate]
                                                          userInfo:nil];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    [self.view removeFromSuperview];
}

- (IBAction)accountAction:(id)sender
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"JFIAccount" bundle:nil];
    JFIAccountViewController *accountViewController = [storyboard instantiateViewControllerWithIdentifier:@"JFIAccountViewController"];
    [self presentViewController:accountViewController animated:YES completion:nil];
}

- (IBAction)fontSizeAction:(id)sender
{
    if (self.currenToolbarView != nil) {
        [self.currenToolbarView setHidden:YES];
        self.currenToolbarView = nil;
    }
    
    [self.fontSizeToolbarView setHidden:NO];
    self.currenToolbarView = self.fontSizeToolbarView;
}

- (IBAction)themeAction:(id)sender
{
    if (self.currenToolbarView != nil) {
        [self.currenToolbarView setHidden:YES];
        self.currenToolbarView = nil;
    }
    
    [self.themeToolbarView setHidden:NO];
    self.currenToolbarView = self.themeToolbarView;
    
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
    NSLog(@"fontSizeChanged fontSize:%f", self.fontSizeSlider.value);
    self.fontSizeApply = YES;
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    delegate.fontSize = self.fontSizeSlider.value;
    [[NSNotificationCenter defaultCenter] postNotificationName:JFISetFontSizeNotification
                                                        object:[[UIApplication sharedApplication] delegate]
                                                      userInfo:nil];
}

@end
