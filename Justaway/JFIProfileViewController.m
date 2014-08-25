#import "JFIProfileViewController.h"
#import "JFIHTTPImageOperation.h"
#import "JFIAppDelegate.h"
#import "JFITheme.h"
#import "UIColor+Hex.h"
#import "UIView+Border.h"

@interface JFIProfileViewController ()

@end

@implementation JFIProfileViewController

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
    
    self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFill;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    JFITheme *theme = [JFITheme sharedTheme];
    self.view.backgroundColor = theme.mainBackgroundColor;
    
    [self.tabView addTopBorderWithColor:theme.mainHighlightBackgroundColor andWidth:0.5f];
    [self.tabView addBottomBorderWithColor:theme.mainHighlightBackgroundColor andWidth:0.5f];
    [self.tabFollowingView addLeftBorderWithColor:theme.mainHighlightBackgroundColor andWidth:0.5f];
    [self.tabFollowersView addLeftBorderWithColor:theme.mainHighlightBackgroundColor andWidth:0.5f];
    [self.tabListsView addLeftBorderWithColor:theme.mainHighlightBackgroundColor andWidth:0.5f];
    [self.tabFavoritesView addLeftBorderWithColor:theme.mainHighlightBackgroundColor andWidth:0.5f];
    
    self.tweetsLabel.textColor = theme.menuHighlightTextColor;
    self.followingLabel.textColor = theme.menuTextColor;
    self.followersLabel.textColor = theme.menuTextColor;
    self.listsLabel.textColor = theme.menuTextColor;
    self.favoritesLabel.textColor = theme.menuTextColor;
    
    NSLog(@"[%@] %s userID:%@", NSStringFromClass([self class]), sel_getName(_cmd), self.userID);
    
    JFIAppDelegate *delegate = (JFIAppDelegate *) [[UIApplication sharedApplication] delegate];
    JFIAccount *account = [delegate getAccount];
    STTwitterAPI *twitter = [delegate getTwitter];
    [twitter getUsersShowForUserID:self.userID
                       orScreenName:nil
                    includeEntities:nil
                       successBlock:^(NSDictionary *user) {
                           
                           [self loadIcon:[[NSURL alloc] initWithString:[[user valueForKey:@"profile_image_url"] stringByReplacingOccurrencesOfString:@"_normal"
                                                                                                                                           withString:@"_bigger"]]];
                           
                           self.profileView.backgroundColor = [UIColor colorWithHex:[user valueForKey:@"profile_background_color"]];
                           if ([user valueForKey:@"profile_banner_url"]) {
                               [self loadBackground:[[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@/mobile_retina", [user valueForKey:@"profile_banner_url"]]]];
                           } else {
                               self.backgroundImageView.image = nil;
                           }
                           
                           self.displayName.text = [user valueForKey:@"name"];
                           self.scrennName.text = [NSString stringWithFormat:@"@%@", [user valueForKey:@"screen_name"]];
    }
                        errorBlock:^(NSError *error) {
                            NSLog(@"[%@] %s error:%@", NSStringFromClass([self class]), sel_getName(_cmd), [error localizedDescription]);
    }];
    
    self.followedBy.hidden = YES;
    
    [twitter getFriendshipShowForSourceID:account.userID
                       orSourceScreenName:nil
                                 targetID:self.userID
                       orTargetScreenName:nil
                             successBlock:^(NSDictionary *relationship) {
                                 NSLog(@"[%@] %s following:%@", NSStringFromClass([self class]), sel_getName(_cmd), [relationship valueForKeyPath:@"relationship.source.following"]);
                                 NSLog(@"[%@] %s followed_by:%@", NSStringFromClass([self class]), sel_getName(_cmd), [relationship valueForKeyPath:@"relationship.source.followed_by"]);
                                 
                                 if ([[relationship valueForKeyPath:@"relationship.source.following"] boolValue]) {
                                     // TODO: Set follow button label
                                 } else {
                                     // TODO: Set follow button label
                                 }
                                 
                                 if ([[relationship valueForKeyPath:@"relationship.source.followed_by"] boolValue]) {
                                     self.followedBy.hidden = NO;
                                 }
    }
                               errorBlock:^(NSError *error) {
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
//    self.tabView.layer.sublayers = nil;
//    self.tabFollowingView.layer.sublayers = nil;
//    self.tabFollowersView.layer.sublayers = nil;
//    self.tabListsView.layer.sublayers = nil;
//    self.tabFavoritesView.layer.sublayers = nil;
}

- (void)loadIcon:(NSURL *)url
{
    [JFIHTTPImageOperation loadURL:url
                       processType:ImageProcessTypeIcon64
                           handler:^(NSHTTPURLResponse *response, UIImage *image, NSError *error) {
                               self.iconImageView.image = image;
                           }];
}

- (void)loadBackground:(NSURL *)url
{
    [JFIHTTPImageOperation loadURL:url
                       processType:ImageProcessTypeNone
                           handler:^(NSHTTPURLResponse *response, UIImage *image, NSError *error) {
                               self.backgroundImageView.image = image;
                           }];
}

- (IBAction)closeAction:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
